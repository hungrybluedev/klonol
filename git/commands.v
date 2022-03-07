module git

import os

pub fn git_is_installed() bool {
	result := os.execute('git --version')
	return result.exit_code == 0 && result.output.contains('git version')
}

pub fn git_can_use_ssh(base_url string) bool {
	result := os.execute('ssh -T git@$base_url')
	return result.output.contains('successfully authenticated')
}
