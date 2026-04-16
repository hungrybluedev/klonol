module git

import common
import os
import rand

fn unique_tmp_dir() string {
	return os.join_path(os.temp_dir(), 'klonol_test_${rand.ulid()}')
}

fn setup_bare_repo(tmp string) !string {
	os.mkdir_all(tmp)!
	bare_path := os.join_path(tmp, 'remote.git')
	result := os.execute('git init --bare ${bare_path}')
	if result.exit_code != 0 {
		return error('Failed to init bare repo: ${result.output}')
	}
	return bare_path
}

fn setup_bare_repo_with_commit(tmp string) !string {
	bare_path := setup_bare_repo(tmp)!

	work_path := os.join_path(tmp, 'work')
	mut result := os.execute('git clone ${bare_path} ${work_path}')
	if result.exit_code != 0 {
		return error('Failed to clone bare repo: ${result.output}')
	}

	os.write_file(os.join_path(work_path, 'README.md'), 'initial content')!

	result = os.execute('git -C ${work_path} add .')
	if result.exit_code != 0 {
		return error('Failed to git add: ${result.output}')
	}

	result =
		os.execute('git -C ${work_path} -c user.name="Test" -c user.email="test@test.com" commit -m "initial commit"')
	if result.exit_code != 0 {
		return error('Failed to git commit: ${result.output}')
	}

	result = os.execute('git -C ${work_path} push')
	if result.exit_code != 0 {
		return error('Failed to git push: ${result.output}')
	}

	return bare_path
}

fn test_is_installed() {
	assert is_installed() == true
}

fn test_clone_repository() {
	tmp := unique_tmp_dir()
	defer {
		os.rmdir_all(tmp) or {}
	}

	bare_path := setup_bare_repo_with_commit(tmp) or {
		assert false, 'setup failed: ${err}'
		return
	}

	repo := common.Repository{
		full_name: 'testowner/remote'
		repo_name: 'remote'
		ssh_url:   bare_path
	}

	old_dir := os.getwd()
	clone_dir := os.join_path(tmp, 'clones')
	os.mkdir_all(clone_dir) or {
		assert false, 'mkdir failed'
		return
	}
	os.chdir(clone_dir) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	clone_repository(repo, true, false) or {
		assert false, 'clone_repository failed: ${err}'
		return
	}
	assert os.exists(os.join_path(clone_dir, 'testowner', 'remote'))
}

fn test_clone_repository_already_exists() {
	tmp := unique_tmp_dir()
	defer {
		os.rmdir_all(tmp) or {}
	}

	bare_path := setup_bare_repo_with_commit(tmp) or {
		assert false, 'setup failed: ${err}'
		return
	}

	clone_dir := os.join_path(tmp, 'clones')
	os.mkdir_all(os.join_path(clone_dir, 'testowner', 'existing-repo')) or {
		assert false, 'mkdir failed'
		return
	}

	repo := common.Repository{
		full_name: 'testowner/existing-repo'
		repo_name: 'existing-repo'
		ssh_url:   bare_path
	}

	old_dir := os.getwd()
	os.chdir(clone_dir) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	// Should succeed without error (skips cloning)
	clone_repository(repo, true, false) or {
		assert false, 'clone_repository should not fail for existing dir: ${err}'
		return
	}
}

fn test_pull_repository_nonexistent() {
	tmp := unique_tmp_dir()
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed'
		return
	}
	defer {
		os.rmdir_all(tmp) or {}
	}

	repo := common.Repository{
		full_name: 'user/nonexistent-repo'
		repo_name: 'nonexistent-repo'
		ssh_url:   'git@example.com:user/nonexistent.git'
	}

	old_dir := os.getwd()
	os.chdir(tmp) or {
		assert false, 'chdir failed'
		return
	}
	defer {
		os.chdir(old_dir) or {}
	}

	// Should succeed without error (skips pulling)
	pull_repository(repo, true) or {
		assert false, 'pull_repository should not fail for nonexistent repo: ${err}'
		return
	}
}

fn test_pull_repository_empty_repo() {
	tmp := unique_tmp_dir()
	defer {
		os.rmdir_all(tmp) or {}
	}

	// Create a bare repo with no commits
	bare_path := setup_bare_repo(tmp) or {
		assert false, 'setup failed: ${err}'
		return
	}

	repo := common.Repository{
		full_name: 'testowner/empty-repo'
		repo_name: 'empty-repo'
		ssh_url:   bare_path
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

	// Clone the empty repo
	clone_repository(repo, false, false) or {
		assert false, 'clone failed: ${err}'
		return
	}
	assert os.exists(os.join_path(clone_dir, 'testowner', 'empty-repo'))

	// Pull should succeed without error (skips empty repo)
	pull_repository(repo, true) or {
		assert false, 'pull_repository should not fail for empty repo: ${err}'
		return
	}
}

fn test_pull_repository_up_to_date() {
	tmp := unique_tmp_dir()
	defer {
		os.rmdir_all(tmp) or {}
	}

	bare_path := setup_bare_repo_with_commit(tmp) or {
		assert false, 'setup failed: ${err}'
		return
	}

	repo := common.Repository{
		full_name: 'testowner/remote'
		repo_name: 'remote'
		ssh_url:   bare_path
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

	// Clone first
	clone_repository(repo, false, false) or {
		assert false, 'clone failed: ${err}'
		return
	}

	// Pull should succeed (already up to date)
	pull_repository(repo, true) or {
		assert false, 'pull_repository failed: ${err}'
		return
	}
}
