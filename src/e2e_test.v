module main

import common
import git
import mock
import os
import rand

fn e2e_unique_tmp_dir() string {
	return os.join_path(os.temp_dir(), 'klonol_e2e_${rand.ulid()}')
}

fn e2e_setup_bare_repo(tmp string, name string) !string {
	bare_path := os.join_path(tmp, '${name}.git')
	mut result := os.execute('git init --bare ${bare_path}')
	if result.exit_code != 0 {
		return error('Failed to init bare repo: ${result.output}')
	}

	work_path := os.join_path(tmp, '${name}_work')
	result = os.execute('git clone ${bare_path} ${work_path}')
	if result.exit_code != 0 {
		return error('Failed to clone: ${result.output}')
	}
	os.write_file(os.join_path(work_path, 'README.md'), 'initial content for ${name}')!
	result = os.execute('git -C ${work_path} add .')
	if result.exit_code != 0 {
		return error('Failed to add: ${result.output}')
	}
	result = os.execute('git -C ${work_path} -c user.name="Test" -c user.email="test@test.com" commit -m "init"')
	if result.exit_code != 0 {
		return error('Failed to commit: ${result.output}')
	}
	result = os.execute('git -C ${work_path} push')
	if result.exit_code != 0 {
		return error('Failed to push: ${result.output}')
	}
	return bare_path
}

fn test_e2e_clone_from_mock_provider() {
	tmp := e2e_unique_tmp_dir()
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed'
		return
	}
	defer {
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare_a := e2e_setup_bare_repo(tmp, 'repo-alpha') or {
		assert false, 'setup repo-alpha failed: ${err}'
		return
	}
	bare_b := e2e_setup_bare_repo(tmp, 'repo-beta') or {
		assert false, 'setup repo-beta failed: ${err}'
		return
	}

	mock.set_repositories([
		common.Repository{
			full_name: 'testowner/repo-alpha'
			repo_name: 'repo-alpha'
			ssh_url:   bare_a
		},
		common.Repository{
			full_name: 'testowner/repo-beta'
			repo_name: 'repo-beta'
			ssh_url:   bare_b
		},
	])

	credentials := get_credentials_for(.mock, '') or {
		assert false, 'get_credentials_for mock failed: ${err}'
		return
	}
	assert credentials.provider == .mock

	fetched := mock.get_repositories(credentials) or {
		assert false, 'get_repositories failed: ${err}'
		return
	}
	assert fetched.len == 2

	clone_dir := os.join_path(tmp, 'clones')
	os.mkdir_all(clone_dir) or {
		assert false, 'mkdir clones failed'
		return
	}
	old_dir := os.getwd()
	os.chdir(clone_dir) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	git.clone_all_repositories(fetched, true, false) or {
		assert false, 'clone_all_repositories failed: ${err}'
		return
	}

	assert os.exists(os.join_path(clone_dir, 'testowner', 'repo-alpha'))
	assert os.exists(os.join_path(clone_dir, 'testowner', 'repo-beta'))
	assert os.exists(os.join_path(clone_dir, 'testowner', 'repo-alpha', 'README.md'))
	assert os.exists(os.join_path(clone_dir, 'testowner', 'repo-beta', 'README.md'))
}

fn test_e2e_pull_after_clone() {
	tmp := e2e_unique_tmp_dir()
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed'
		return
	}
	defer {
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare_path := e2e_setup_bare_repo(tmp, 'pull-test') or {
		assert false, 'setup failed: ${err}'
		return
	}

	repos := [
		common.Repository{
			full_name: 'testowner/pull-test'
			repo_name: 'pull-test'
			ssh_url:   bare_path
		},
	]
	mock.set_repositories(repos)

	fetched := mock.get_repositories(common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}) or {
		assert false, 'get_repositories failed: ${err}'
		return
	}

	clone_dir := os.join_path(tmp, 'clones')
	os.mkdir_all(clone_dir) or {
		assert false, 'mkdir failed'
		return
	}
	old_dir := os.getwd()
	os.chdir(clone_dir) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	git.clone_all_repositories(fetched, false, false) or {
		assert false, 'clone failed: ${err}'
		return
	}
	assert os.exists(os.join_path(clone_dir, 'testowner', 'pull-test'))

	git.pull_existing_repositories(fetched, true) or {
		assert false, 'pull failed: ${err}'
		return
	}
}

fn test_e2e_pull_nonexistent_repos() {
	tmp := e2e_unique_tmp_dir()
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed'
		return
	}
	defer {
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	repos := [
		common.Repository{
			full_name: 'user/does-not-exist'
			repo_name: 'does-not-exist'
			ssh_url:   '/nonexistent/path.git'
		},
	]
	mock.set_repositories(repos)

	fetched := mock.get_repositories(common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}) or {
		assert false, 'get_repositories failed: ${err}'
		return
	}

	old_dir := os.getwd()
	os.chdir(tmp) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	git.pull_existing_repositories(fetched, true) or {
		assert false, 'pull should not fail for nonexistent repos: ${err}'
		return
	}
}

fn test_e2e_clone_idempotent() {
	tmp := e2e_unique_tmp_dir()
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed'
		return
	}
	defer {
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare_path := e2e_setup_bare_repo(tmp, 'idem-repo') or {
		assert false, 'setup failed: ${err}'
		return
	}

	repos := [
		common.Repository{
			full_name: 'testowner/idem-repo'
			repo_name: 'idem-repo'
			ssh_url:   bare_path
		},
	]
	mock.set_repositories(repos)

	fetched := mock.get_repositories(common.Credential{
		provider:     .mock
		username:     'test'
		access_token: 'unused'
	}) or {
		assert false, 'get_repositories failed: ${err}'
		return
	}

	clone_dir := os.join_path(tmp, 'clones')
	os.mkdir_all(clone_dir) or {
		assert false, 'mkdir failed'
		return
	}
	old_dir := os.getwd()
	os.chdir(clone_dir) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	git.clone_all_repositories(fetched, true, false) or {
		assert false, 'first clone failed: ${err}'
		return
	}
	git.clone_all_repositories(fetched, true, false) or {
		assert false, 'second clone should not fail: ${err}'
		return
	}
	assert os.exists(os.join_path(clone_dir, 'testowner', 'idem-repo'))
}
