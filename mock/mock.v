module mock

import common
import os
import x.json2

// Overrides the state file, so parallel test files and spawned klonol
// processes do not clobber each other. Children inherit it via the env.
const mock_data_env = 'KLONOL_MOCK_DATA'

fn mock_data_path() string {
	if path := os.getenv_opt(mock_data_env) {
		if path != '' {
			return path
		}
	}
	return os.join_path(os.temp_dir(), 'klonol_mock_repos.json')
}

pub fn use_data_path(path string) {
	os.setenv(mock_data_env, path, true)
}

fn json_escape(s string) string {
	return s.replace('\\', '\\\\')
}

pub fn set_repositories(repos []common.Repository) {
	mut items := []string{}
	for repo in repos {
		items << '{"full_name": "${json_escape(repo.full_name)}", "name": "${json_escape(repo.repo_name)}", "ssh_url": "${json_escape(repo.ssh_url)}", "clone_url": "${json_escape(repo.clone_url)}", "archived": ${repo.archived}}'
	}
	json_str := '[${items.join(',')}]'
	os.write_file(mock_data_path(), json_str) or { panic(err) }
}

pub fn clear() {
	os.rm(mock_data_path()) or {}
}

pub fn get_repositories(credentials common.Credential) ![]common.Repository {
	path := mock_data_path()
	if !os.exists(path) {
		return []
	}
	content := os.read_file(path)!
	raw_data := json2.decode[json2.Any](content)!
	mut repos := []common.Repository{}
	for item in raw_data.as_array() {
		repos << common.parse_repository(item.as_map())!
	}
	return repos
}
