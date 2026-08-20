module main

import common
import mock
import os
import rand

// Drives the compiled executable, covering main(): flags, mapping, exit codes.

fn cli_exe_path() string {
	base := os.join_path(os.temp_dir(), 'klonol_cli_test')
	$if windows {
		return base + '.exe'
	}
	return base
}

const cli_exe = cli_exe_path()

fn testsuite_begin() {
	mock.use_data_path(os.join_path(os.temp_dir(), 'klonol_mock_cli_${rand.ulid()}.json'))

	project_dir := os.dir(@FILE)
	build :=
		os.execute('${os.quoted_path(@VEXE)} ${os.quoted_path(project_dir)} -o ${os.quoted_path(cli_exe)}')
	assert build.exit_code == 0, 'failed to build the klonol executable: ${build.output}'
	assert os.exists(cli_exe), 'no executable was produced at ${cli_exe}'
}

fn testsuite_end() {
	mock.clear()
	os.rm(cli_exe) or {}
}

fn run_cli(args string) os.Result {
	return os.execute('${os.quoted_path(cli_exe)} ${args}')
}

// A bare repo with one commit, clonable over a plain filesystem path.
fn cli_setup_bare_repo(tmp string, repo string) !string {
	bare_path := os.join_path(tmp, '${repo}.git')
	mut result := os.execute('git init --bare ${os.quoted_path(bare_path)}')
	if result.exit_code != 0 {
		return error('failed to init bare repo: ${result.output}')
	}

	work_path := os.join_path(tmp, '${repo}_work')
	result = os.execute('git clone ${os.quoted_path(bare_path)} ${os.quoted_path(work_path)}')
	if result.exit_code != 0 {
		return error('failed to clone: ${result.output}')
	}
	os.write_file(os.join_path(work_path, 'README.md'), 'content for ${repo}')!
	result = os.execute('git -C ${os.quoted_path(work_path)} add .')
	if result.exit_code != 0 {
		return error('failed to add: ${result.output}')
	}
	result =
		os.execute('git -C ${os.quoted_path(work_path)} -c user.name="Test" -c user.email="test@test.com" commit -m "init"')
	if result.exit_code != 0 {
		return error('failed to commit: ${result.output}')
	}
	result = os.execute('git -C ${os.quoted_path(work_path)} push')
	if result.exit_code != 0 {
		return error('failed to push: ${result.output}')
	}
	return bare_path
}

fn test_cli_reports_its_version() {
	result := run_cli('--version')
	assert result.exit_code == 0
	assert result.output.contains(name)
	assert result.output.contains(version)
}

fn test_cli_help_documents_the_flags() {
	result := run_cli('--help')
	assert result.exit_code == 0
	assert result.output.contains('--provider')
	assert result.output.contains('--action')
	assert result.output.contains('--use-https')
}

fn test_cli_rejects_an_unknown_provider() {
	result := run_cli('-p bogus -a list')
	assert result.exit_code == 1
	assert result.output.contains('Invalid provider: bogus')
}

fn test_cli_rejects_an_unknown_action() {
	result := run_cli('-p mock -a bogus')
	assert result.exit_code == 1
	assert result.output.contains('Invalid action: bogus')
}

fn test_cli_rejects_extra_arguments() {
	result := run_cli('-p mock -a list unexpected')
	assert result.exit_code == 1
	assert result.output.contains('Unnecessary arguments: unexpected')
}

fn test_cli_lists_nothing_when_provider_is_empty() {
	mock.clear()
	result := run_cli('-p mock -a list')
	assert result.exit_code == 0
	assert result.output.contains('Count: 0')
}

fn test_cli_list_omits_archived_repositories() {
	defer {
		mock.clear()
	}
	mock.set_repositories([
		common.Repository{
			full_name: 'acme/alpha'
			repo_name: 'alpha'
		},
		common.Repository{
			full_name: 'acme/beta'
			repo_name: 'beta'
		},
		common.Repository{
			full_name: 'acme/retired'
			repo_name: 'retired'
			archived:  true
		},
	])

	result := run_cli('-p mock -a list')
	assert result.exit_code == 0
	assert result.output.contains('acme/alpha')
	assert result.output.contains('acme/beta')
	assert !result.output.contains('acme/retired')
	assert result.output.contains('Count: 2 (1 excluded)')
}

fn test_cli_clone_creates_the_working_copies() {
	tmp := os.join_path(os.temp_dir(), 'klonol_cli_clone_${rand.ulid()}')
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed: ${err}'
		return
	}
	previous_dir := os.getwd()
	defer {
		os.chdir(previous_dir) or {}
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare := cli_setup_bare_repo(tmp, 'alpha') or {
		assert false, 'fixture setup failed: ${err}'
		return
	}
	mock.set_repositories([
		common.Repository{
			full_name: 'acme/alpha'
			repo_name: 'alpha'
			ssh_url:   bare
		},
	])

	destination := os.join_path(tmp, 'destination')
	os.mkdir_all(destination) or {
		assert false, 'mkdir destination failed: ${err}'
		return
	}
	os.chdir(destination) or {
		assert false, 'chdir failed: ${err}'
		return
	}

	result := run_cli('-p mock -a clone')
	assert result.exit_code == 0, 'clone failed: ${result.output}'
	assert os.exists(os.join_path(destination, 'acme', 'alpha', 'README.md'))
}

fn test_cli_use_https_prefers_the_clone_url() {
	tmp := os.join_path(os.temp_dir(), 'klonol_cli_https_${rand.ulid()}')
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed: ${err}'
		return
	}
	previous_dir := os.getwd()
	defer {
		os.chdir(previous_dir) or {}
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare := cli_setup_bare_repo(tmp, 'gamma') or {
		assert false, 'fixture setup failed: ${err}'
		return
	}
	// ssh_url points at nothing: success proves --use-https chose clone_url.
	mock.set_repositories([
		common.Repository{
			full_name: 'acme/gamma'
			repo_name: 'gamma'
			ssh_url:   os.join_path(tmp, 'does-not-exist.git')
			clone_url: bare
		},
	])

	destination := os.join_path(tmp, 'destination')
	os.mkdir_all(destination) or {
		assert false, 'mkdir destination failed: ${err}'
		return
	}
	os.chdir(destination) or {
		assert false, 'chdir failed: ${err}'
		return
	}

	result := run_cli('-p mock -a clone --use-https')
	assert result.exit_code == 0, 'clone over https failed: ${result.output}'
	assert os.exists(os.join_path(destination, 'acme', 'gamma', 'README.md'))
}

fn test_cli_clone_is_idempotent() {
	tmp := os.join_path(os.temp_dir(), 'klonol_cli_idem_${rand.ulid()}')
	os.mkdir_all(tmp) or {
		assert false, 'mkdir failed: ${err}'
		return
	}
	previous_dir := os.getwd()
	defer {
		os.chdir(previous_dir) or {}
		os.rmdir_all(tmp) or {}
		mock.clear()
	}

	bare := cli_setup_bare_repo(tmp, 'delta') or {
		assert false, 'fixture setup failed: ${err}'
		return
	}
	mock.set_repositories([
		common.Repository{
			full_name: 'acme/delta'
			repo_name: 'delta'
			ssh_url:   bare
		},
	])

	destination := os.join_path(tmp, 'destination')
	os.mkdir_all(destination) or {
		assert false, 'mkdir destination failed: ${err}'
		return
	}
	os.chdir(destination) or {
		assert false, 'chdir failed: ${err}'
		return
	}

	first := run_cli('-p mock -a clone')
	assert first.exit_code == 0, 'first clone failed: ${first.output}'

	second := run_cli('-p mock -a clone -v')
	assert second.exit_code == 0, 'second clone failed: ${second.output}'
	assert second.output.contains('already exists')

	pull := run_cli('-p mock -a pull -v')
	assert pull.exit_code == 0, 'pull failed: ${pull.output}'
}
