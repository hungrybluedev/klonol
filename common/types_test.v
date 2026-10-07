module common

import x.json2

fn test_parse_repository_valid() {
	data := {
		'full_name': json2.Any('user/my-repo')
		'name':      json2.Any('my-repo')
		'ssh_url':   json2.Any('git@github.com:user/my-repo.git')
	}
	repo := parse_repository(data) or {
		assert false, 'parse_repository should not fail for valid data'
		return
	}
	assert repo.full_name == 'user/my-repo'
	assert repo.repo_name == 'my-repo'
	assert repo.ssh_url == 'git@github.com:user/my-repo.git'
}

fn test_parse_repository_missing_full_name_uses_name() {
	data := {
		'name':    json2.Any('my-repo')
		'ssh_url': json2.Any('git@github.com:user/my-repo.git')
	}
	repo := parse_repository(data) or {
		assert false, 'parse_repository should not fail'
		return
	}
	assert repo.full_name == 'my-repo'
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
		full_name: 'user/test-repo'
		repo_name: 'test-repo'
		ssh_url:   'git@github.com:user/test-repo.git'
		clone_url: 'https://github.com/user/test-repo.git'
	}
	result := repo.str()
	assert result == 'user/test-repo'
}

fn test_effective_url_ssh() {
	repo := Repository{
		full_name: 'user/test-repo'
		repo_name: 'test-repo'
		ssh_url:   'git@github.com:user/test-repo.git'
		clone_url: 'https://github.com/user/test-repo.git'
	}
	assert repo.effective_url(false) == 'git@github.com:user/test-repo.git'
}

fn test_effective_url_https() {
	repo := Repository{
		full_name: 'user/test-repo'
		repo_name: 'test-repo'
		ssh_url:   'git@github.com:user/test-repo.git'
		clone_url: 'https://github.com/user/test-repo.git'
	}
	assert repo.effective_url(true) == 'https://github.com/user/test-repo.git'
}

fn test_effective_url_https_fallback_to_ssh() {
	repo := Repository{
		full_name: 'user/test-repo'
		repo_name: 'test-repo'
		ssh_url:   'git@github.com:user/test-repo.git'
	}
	assert repo.effective_url(true) == 'git@github.com:user/test-repo.git'
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

struct NameCase {
	full_name string
	why       string
}

const safe_names = [
	NameCase{'hungrybluedev/klonol', 'this project'},
	NameCase{'hungrybluedev/SetTheoryForBeginners', 'real Forgejo repo, mixed case'},
	NameCase{'hungrybluedev/cc-form-formbackend-archived', 'real Forgejo repo, many hyphens'},
	NameCase{'hungrybluedev/eva1', 'real Forgejo repo, digits'},
	NameCase{'vlang/v', 'one-letter repo'},
	NameCase{'hungrybluedev/.github', 'leading dot, the GitHub profile repo convention'},
	NameCase{'hungrybluedev/hungrybluedev.github.io', 'Pages repo, several dots'},
	NameCase{'some_org/snake_case_repo', 'underscores'},
	NameCase{'owner/foo..bar', 'two dots inside a name are not a parent reference'},
	NameCase{'my-project', 'bare name, the fallback when full_name is missing'},
	NameCase{'owner/-leading-dash', 'a leading dash is legal; git clone -- keeps it from parsing as an option'},
]

const unsafe_names = [
	NameCase{'', 'empty'},
	NameCase{'.', 'current directory'},
	NameCase{'..', 'parent directory'},
	NameCase{'../evil', 'path traversal out of the working directory'},
	NameCase{'owner/..', 'traversal in the repo segment'},
	NameCase{'../../.ssh', 'traversal aimed at a dotfile'},
	NameCase{'owner/.', 'current-directory repo segment'},
	NameCase{'/etc/passwd', 'absolute path'},
	NameCase{'owner/', 'empty repo segment'},
	NameCase{'/repo', 'empty owner segment'},
	NameCase{'owner//repo', 'empty middle segment'},
	NameCase{'owner/repo/extra', 'more than owner/repo'},
	NameCase{'owner\\..\\evil', 'backslash traversal on Windows'},
	NameCase{'C:/evil', 'Windows drive path'},
	NameCase{'~/evil', 'home directory shorthand'},
	NameCase{'owner/re po', 'space'},
	NameCase{'owner/repo;rm -rf ~', 'shell command separator'},
	NameCase{'owner/\$(id)', 'shell command substitution'},
	NameCase{'owner/`id`', 'backtick substitution'},
	NameCase{'owner/repo\nevil', 'newline'},
	NameCase{'owner/repo\x00', 'NUL byte'},
	NameCase{'owner/--upload-pack=touch pwned', 'git option injection, the shape behind CVE-2017-1000117'},
	NameCase{'owner/répo', 'non-ASCII, which no supported forge allows'},
]

fn repo_data(full_name string) map[string]json2.Any {
	return {
		'full_name': json2.Any(full_name)
		'name':      json2.Any('repo')
		'ssh_url':   json2.Any('git@example.com:owner/repo.git')
	}
}

fn test_parse_repository_accepts_safe_names() {
	for c in safe_names {
		repo := parse_repository(repo_data(c.full_name)) or {
			assert false, '${c.full_name} (${c.why}) was rejected: ${err}'
			continue
		}
		assert repo.full_name == c.full_name, c.why
	}
}

fn test_parse_repository_rejects_unsafe_names() {
	for c in unsafe_names {
		parse_repository(repo_data(c.full_name)) or {
			assert err.msg().contains('unsafe repository name'), c.why
			continue
		}
		assert false, '${c.full_name} (${c.why}) was accepted'
	}
}

fn test_parse_repository_rejects_unsafe_fallback_name() {
	data := {
		'name':    json2.Any('..')
		'ssh_url': json2.Any('git@example.com:owner/repo.git')
	}
	parse_repository(data) or {
		assert err.msg().contains('unsafe repository name')
		return
	}
	assert false, 'a name of `..` was accepted through the full_name fallback'
}
