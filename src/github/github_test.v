module github

import common
import x.json2

fn parse_repos_from_github_json(raw_json string) ![]common.Repository {
	raw_data := json2.decode[json2.Any](raw_json)!
	repo_list := raw_data.as_map()['items']!.as_array()
	mut repos := []common.Repository{}
	for item in repo_list {
		repos << common.parse_repository(item.as_map())!
	}
	return repos
}

fn test_github_response_parsing() {
	raw_json := '{"items": [{"name": "repo1", "ssh_url": "git@github.com:user/repo1.git"}, {"name": "repo2", "ssh_url": "git@github.com:user/repo2.git"}]}'
	repos := parse_repos_from_github_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 2
	assert repos[0].repo_name == 'repo1'
	assert repos[0].ssh_url == 'git@github.com:user/repo1.git'
	assert repos[1].repo_name == 'repo2'
	assert repos[1].ssh_url == 'git@github.com:user/repo2.git'
}

fn test_github_empty_items() {
	raw_json := '{"items": []}'
	repos := parse_repos_from_github_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 0
}

fn test_github_multiple_repos_with_varied_names() {
	raw_json := '{"items": [{"name": "my-project", "ssh_url": "git@github.com:user/my-project.git"}, {"name": "another_repo", "ssh_url": "git@github.com:user/another_repo.git"}, {"name": "repo.with.dots", "ssh_url": "git@github.com:user/repo.with.dots.git"}]}'
	repos := parse_repos_from_github_json(raw_json) or {
		assert false, 'parsing failed: ${err}'
		return
	}
	assert repos.len == 3
	assert repos[0].repo_name == 'my-project'
	assert repos[1].repo_name == 'another_repo'
	assert repos[2].repo_name == 'repo.with.dots'
}
