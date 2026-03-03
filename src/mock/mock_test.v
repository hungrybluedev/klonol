module mock

import common

fn test_set_and_get_repositories() {
	defer {
		clear()
	}
	expected := [
		common.Repository{
			repo_name: 'repo-a'
			ssh_url:   '/tmp/bare-a.git'
		},
		common.Repository{
			repo_name: 'repo-b'
			ssh_url:   '/tmp/bare-b.git'
		},
	]
	set_repositories(expected)

	creds := common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}
	repos := get_repositories(creds) or {
		assert false, 'should not fail: ${err}'
		return
	}
	assert repos.len == 2
	assert repos[0].repo_name == 'repo-a'
	assert repos[0].ssh_url == '/tmp/bare-a.git'
	assert repos[1].repo_name == 'repo-b'
	assert repos[1].ssh_url == '/tmp/bare-b.git'
}

fn test_get_repositories_empty_after_clear() {
	clear()

	creds := common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}
	repos := get_repositories(creds) or {
		assert false, 'should not fail: ${err}'
		return
	}
	assert repos.len == 0
}

fn test_get_repositories_overwrite() {
	defer {
		clear()
	}
	set_repositories([
		common.Repository{
			repo_name: 'old-repo'
			ssh_url:   '/tmp/old.git'
		},
	])
	set_repositories([
		common.Repository{
			repo_name: 'new-repo'
			ssh_url:   '/tmp/new.git'
		},
	])

	creds := common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}
	repos := get_repositories(creds) or {
		assert false, 'should not fail: ${err}'
		return
	}
	assert repos.len == 1
	assert repos[0].repo_name == 'new-repo'
}
