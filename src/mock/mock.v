module mock

import common
import os
import x.json2

const mock_data_path = os.join_path(os.temp_dir(), 'klonol_mock_repos.json')

fn json_escape(s string) string {
	return s.replace('\\', '\\\\')
}

pub fn set_repositories(repos []common.Repository) {
	mut items := []string{}
	for repo in repos {
		items << '{"name": "${json_escape(repo.repo_name)}", "ssh_url": "${json_escape(repo.ssh_url)}"}'
	}
	json_str := '[${items.join(',')}]'
	os.write_file(mock_data_path, json_str) or { panic(err) }
}

pub fn clear() {
	os.rm(mock_data_path) or {}
}

pub fn get_repositories(credentials common.Credential) ![]common.Repository {
	if !os.exists(mock_data_path) {
		return []
	}
	content := os.read_file(mock_data_path)!
	raw_data := json2.decode[json2.Any](content)!
	mut repos := []common.Repository{}
	for item in raw_data.as_array() {
		repos << common.parse_repository(item.as_map())!
	}
	return repos
}
