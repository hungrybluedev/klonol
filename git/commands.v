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
	local_path := repository.full_name
	if os.exists(local_path) {
		if verbose {
			println('Repository already exists at ${local_path}. Not cloning it.')
		}
		return
	}
	// Create owner directory if it doesn't exist (e.g. "hungrybluedev/")
	owner_dir := os.dir(local_path)
	if owner_dir.len > 0 && !os.exists(owner_dir) {
		os.mkdir_all(owner_dir) or {
			return error('Failed to create directory ${owner_dir}: ${err}')
		}
	}
	print('Cloning repository: ${local_path} ...')
	url := repository.effective_url(use_https)
	clone_result := os.execute('git clone ${url} ${local_path}')
	if clone_result.exit_code != 0 {
		return error('git clone failed for ${local_path}: ${clone_result.output}')
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
	local_path := repository.full_name
	if !os.exists(local_path) {
		if verbose {
			println('Repository does not exist at ${local_path}. Not pulling it.')
		}
		return
	}
	// Skip empty repositories (cloned but no commits on remote)
	head_check := os.execute('git -C ${local_path} rev-parse HEAD')
	if head_check.exit_code != 0 {
		if verbose {
			println('Repository ${local_path} has no commits. Skipping pull.')
		}
		return
	}

	if verbose {
		print('Check if pull is needed for repository: ${local_path} ...')
	}

	update_result := os.execute('git -C ${local_path} remote update')
	if update_result.exit_code != 0 {
		return error('git remote update failed for ${local_path}: ${update_result.output}')
	}
	result := os.execute('git -C ${local_path} status')
	if result.exit_code != 0 {
		return error('git status failed for ${local_path}: ${result.output}')
	}
	if result.output.contains('Your branch is up to date with ') {
		if verbose {
			println(' No pull is needed.')
		}
		return
	}
	if verbose {
		print('Pulling repository: ${local_path} ...')
	}
	pull_result := os.execute('git -C ${local_path} pull')
	if pull_result.exit_code != 0 {
		return error('git pull failed for ${local_path}: ${pull_result.output}')
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
