module github

import common
import x.json2
import time

fn get_data_for_page_number(page int, credentials common.Credential) ![]common.Repository {
	result := common.authorized_get('https://api.github.com/user/repos?affiliation=owner,collaborator,organization_member&page=${page}&per_page=100',
		credentials.access_token).do()!
	raw_data := json2.decode[json2.Any](result.body)!
	repo_list := raw_data.as_array()
	repositories := repo_list.map(common.parse_repository(it.as_map())!)
	return repositories
}

pub fn get_repositories(credentials common.Credential) ![]common.Repository {
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
