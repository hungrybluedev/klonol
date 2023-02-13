module gitea

import common
import net.http
import x.json2
import time

fn get_data_for_page_number(page int, credentials common.Credentials) ![]common.Repository {
	mut request := http.Request{
		url: 'https://${credentials.base_url}/api/v1/users/${credentials.username}/repos?page=${page}&limit=100&access_token=${credentials.access_token}'
		method: .get
	}
	result := request.do()!
	raw_data := json2.raw_decode(result.body)!
	repo_list := raw_data.arr()
	repositories := repo_list.map(common.parse_repository(it.as_map())!)
	return repositories
}

pub fn get_repositories(credentials common.Credentials) ![]common.Repository {
	mut repositories := get_data_for_page_number(1, credentials)!

	for page in 2 .. common.max_page_limit {
		time.sleep(common.sleep_duration)
		current_list := get_data_for_page_number(page, credentials)!
		if current_list.len == 0 {
			break
		}
		repositories << current_list
	}

	return repositories
}
