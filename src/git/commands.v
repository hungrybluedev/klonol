module git

import common
import os
import time

pub fn is_installed() bool {
	result := os.execute('git --version')
	return result.exit_code == 0 && result.output.contains('git version')
}

pub fn can_use_ssh(base_url string) bool {
	result := os.execute('ssh -T git@${base_url}')
	return result.output.contains('successfully authenticated')
}

pub fn clone_repository(repository common.Repository, verbose bool, use_https bool) ! {
	if os.exists(repository.repo_name) {
		if verbose {
			println('Repository already exists at ${repository.repo_name}. Not cloning it.')
		}
		return
	}
	print('Cloning repository: ${repository.repo_name} ...')
	url := repository.effective_url(use_https)
	clone_result := os.execute('git clone ${url}')
	if clone_result.exit_code != 0 {
		return error('git clone failed for ${repository.repo_name}: ${clone_result.output}')
	}
	println(' Done.')
}

pub fn clone_all_repositories(repositories []common.Repository, verbose bool, use_https bool) ! {
	for repository in repositories {
		clone_repository(repository, verbose, use_https)!
		time.sleep(common.sleep_duration)
	}
}

pub fn pull_repository(repository common.Repository, verbose bool) ! {
	if !os.exists(repository.repo_name) {
		if verbose {
			println('Repository does not exist at ${repository.repo_name}. Not pulling it.')
		}
		return
	}
	if verbose {
		print('Check if pull is needed for repository: ${repository.repo_name} ...')
	}

	update_result := os.execute('git -C ${repository.repo_name} remote update')
	if update_result.exit_code != 0 {
		return error('git remote update failed for ${repository.repo_name}: ${update_result.output}')
	}
	result := os.execute('git -C ${repository.repo_name} status')
	if result.exit_code != 0 {
		return error('git status failed for ${repository.repo_name}: ${result.output}')
	}
	if result.output.contains('Your branch is up to date with ') {
		if verbose {
			println(' No pull is needed.')
		}
		return
	}
	if verbose {
		print('Pulling repository: ${repository.repo_name} ...')
	}
	pull_result := os.execute('git -C ${repository.repo_name} pull')
	if pull_result.exit_code != 0 {
		return error('git pull failed for ${repository.repo_name}: ${pull_result.output}')
	}
	if verbose {
		println(' Done.')
	}
}

pub fn pull_existing_repositories(repositories []common.Repository, verbose bool) ! {
	for repository in repositories {
		pull_repository(repository, verbose)!
		time.sleep(common.sleep_duration)
	}
}
