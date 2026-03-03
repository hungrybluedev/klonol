module common

import x.json2

fn test_parse_repository_valid() {
	data := {
		'name':    json2.Any('my-repo')
		'ssh_url': json2.Any('git@github.com:user/my-repo.git')
	}
	repo := parse_repository(data) or {
		assert false, 'parse_repository should not fail for valid data'
		return
	}
	assert repo.repo_name == 'my-repo'
	assert repo.ssh_url == 'git@github.com:user/my-repo.git'
}

fn test_parse_repository_missing_name() {
	data := {
		'ssh_url': json2.Any('git@github.com:user/my-repo.git')
	}
	parse_repository(data) or {
		assert err.msg().len > 0
		return
	}
	assert false, 'parse_repository should fail when name is missing'
}

fn test_parse_repository_missing_ssh_url() {
	data := {
		'name': json2.Any('my-repo')
	}
	parse_repository(data) or {
		assert err.msg().len > 0
		return
	}
	assert false, 'parse_repository should fail when ssh_url is missing'
}

fn test_parse_repository_empty_map() {
	data := map[string]json2.Any{}
	parse_repository(data) or {
		assert err.msg().len > 0
		return
	}
	assert false, 'parse_repository should fail for empty map'
}

fn test_repository_str() {
	repo := Repository{
		repo_name: 'test-repo'
		ssh_url:   'git@github.com:user/test-repo.git'
	}
	result := repo.str()
	assert result == 'Name: test-repo, URL: git@github.com:user/test-repo.git'
}

fn test_credential_to_toml() {
	cred := Credential{
		provider:     .github
		base_url:     'github.com'
		username:     'testuser'
		access_token: 'abc123'
	}
	result := cred.to_toml()
	assert result.contains('[github]')
	assert result.contains('base_url: github.com')
	assert result.contains('username: testuser')
	assert result.contains('access_token: abc123')
}

fn test_credential_to_toml_gitea() {
	cred := Credential{
		provider:     .gitea
		base_url:     'git.example.com'
		username:     'giteauser'
		access_token: 'token456'
	}
	result := cred.to_toml()
	assert result.contains('[gitea]')
	assert result.contains('base_url: git.example.com')
	assert result.contains('username: giteauser')
	assert result.contains('access_token: token456')
}

fn test_credential_file_to_toml() {
	file := CredentialFile{
		credentials: [
			Credential{
				provider:     .github
				username:     'user1'
				access_token: 'token1'
			},
			Credential{
				provider:     .gitea
				base_url:     'git.example.com'
				username:     'user2'
				access_token: 'token2'
			},
		]
	}
	result := file.to_toml()
	assert result.contains('[github]')
	assert result.contains('[gitea]')
	assert result.contains('username: user1')
	assert result.contains('username: user2')
}

fn test_credential_default_base_url() {
	cred := Credential{
		provider:     .github
		username:     'testuser'
		access_token: 'abc123'
	}
	assert cred.base_url == 'github.com'
}
