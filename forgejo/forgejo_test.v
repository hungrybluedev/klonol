module forgejo

import common
import x.json2

fn parse_repos_from_forgejo_json(raw_json string) ![]common.Repository {
	raw_data := json2.decode[json2.Any](raw_json)!
	repo_list := raw_data.as_array()
	mut repos := []common.Repository{}
	for item in repo_list {
		repos << common.parse_repository(item.as_map())!
	}
	return repos
}

fn test_forgejo_response_parsing() {
	raw_json := '[{"name": "repo1", "ssh_url": "git@forgejo.example.com:user/repo1.git"}, {"name": "repo2", "ssh_url": "git@forgejo.example.com:user/repo2.git"}]'
	repos := parse_repos_from_forgejo_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 2
	assert repos[0].repo_name == 'repo1'
	assert repos[0].ssh_url == 'git@forgejo.example.com:user/repo1.git'
	assert repos[1].repo_name == 'repo2'
}

fn test_forgejo_empty_response() {
	raw_json := '[]'
	repos := parse_repos_from_forgejo_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 0
}

fn test_forgejo_single_repo() {
	raw_json := '[{"name": "my-project", "ssh_url": "git@forgejo.example.com:user/my-project.git"}]'
	repos := parse_repos_from_forgejo_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 1
	assert repos[0].repo_name == 'my-project'
	assert repos[0].ssh_url == 'git@forgejo.example.com:user/my-project.git'
}
