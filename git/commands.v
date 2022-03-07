module git

import common
import os
import time

pub fn git_is_installed() bool {
	result := os.execute('git --version')
	return result.exit_code == 0 && result.output.contains('git version')
}

pub fn git_can_use_ssh(base_url string) bool {
	result := os.execute('ssh -T git@$base_url')
	return result.output.contains('successfully authenticated')
}

pub fn clone_repository(repository common.Repository) ? {
	if os.exists(repository.repo_name) {
		println('Repository already exists at ${repository.repo_name}. Not cloning it.')
		return
	}
	print('Cloning repository: $repository.repo_name ...')
	os.execute_or_panic('git clone $repository.ssh_url')
	println(' Done.')
}

pub fn clone_all_repositories(repositories []common.Repository) ? {
	for repository in repositories {
		clone_repository(repository) ?
		time.sleep(common.sleep_duration)
	}
}
