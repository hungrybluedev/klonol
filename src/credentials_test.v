module main

import common
import os

fn test_create_default_config() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_default_config.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	// Ensure file doesn't exist
	os.rm(tmp_path) or {}

	cred := create_default_config(.github, tmp_path) or {
		assert false, 'create_default_config should not fail: ${err}'
		return
	}
	assert cred.provider == .github
	assert cred.username == 'unset_value'
	assert cred.access_token == 'unset_value'
	assert os.exists(tmp_path)

	content := os.read_file(tmp_path) or {
		assert false, 'should be able to read created file'
		return
	}
	assert content.contains('[github]')
	assert content.contains('username: unset_value')
}

fn test_create_default_config_already_exists() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_existing_config.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	os.write_file(tmp_path, 'existing content') or {
		assert false, 'failed to write test file'
		return
	}

	create_default_config(.github, tmp_path) or {
		assert err.msg().contains('already exists')
		return
	}
	assert false, 'create_default_config should fail when file already exists'
}

fn test_load_config_creates_default_when_missing() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_load_missing.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	os.rm(tmp_path) or {}

	cred := load_config(.github, tmp_path) or {
		assert false, 'load_config should not fail: ${err}'
		return
	}
	assert cred.provider == .github
	assert cred.username == 'unset_value'
	assert os.exists(tmp_path)
}

fn test_load_config_reads_existing_github() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_load_existing.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	toml_content := '
[github]
base_url = "github.com"
username = "myuser"
access_token = "mytoken123"
'
	os.write_file(tmp_path, toml_content) or {
		assert false, 'failed to write test file'
		return
	}

	cred := load_config(.github, tmp_path) or {
		assert false, 'load_config should not fail: ${err}'
		return
	}
	assert cred.provider == .github
	assert cred.base_url == 'github.com'
	assert cred.username == 'myuser'
	assert cred.access_token == 'mytoken123'
}

fn test_load_config_reads_existing_gitea() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_load_gitea.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	toml_content := '
[gitea]
base_url = "git.example.com"
username = "giteauser"
access_token = "giteatoken"
'
	os.write_file(tmp_path, toml_content) or {
		assert false, 'failed to write test file'
		return
	}

	cred := load_config(.gitea, tmp_path) or {
		assert false, 'load_config should not fail: ${err}'
		return
	}
	assert cred.provider == .gitea
	assert cred.base_url == 'git.example.com'
	assert cred.username == 'giteauser'
	assert cred.access_token == 'giteatoken'
}

fn test_load_config_missing_provider_section() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_load_wrong_provider.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	toml_content := '
[github]
username = "myuser"
access_token = "mytoken123"
'
	os.write_file(tmp_path, toml_content) or {
		assert false, 'failed to write test file'
		return
	}

	load_config(.gitea, tmp_path) or {
		assert err.msg().contains('credentials for gitea')
		return
	}
	assert false, 'load_config should fail when provider section is missing'
}

fn test_load_config_missing_username() {
	tmp_path := os.join_path(os.temp_dir(), 'klonol_test_no_username.toml')
	defer {
		os.rm(tmp_path) or {}
	}
	toml_content := '
[github]
access_token = "mytoken123"
'
	os.write_file(tmp_path, toml_content) or {
		assert false, 'failed to write test file'
		return
	}

	load_config(.github, tmp_path) or {
		assert err.msg().contains('username')
		return
	}
	assert false, 'load_config should fail when username is missing'
}
