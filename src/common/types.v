module common

import x.json2
import strings

pub enum Provider {
	github
	gitea
}

pub struct CredentialFile {
pub:
	credentials []Credential
}

pub fn (file CredentialFile) to_toml() string {
	mut builder := strings.new_builder(128)
	for cred in file.credentials {
		builder.write_string(cred.to_toml())
	}
	return builder.str()
}

pub struct Credential {
pub:
	provider     Provider @[required]
	base_url     string = 'github.com'
	username     string   @[required]
	access_token string   @[required]
}

fn (c Credential) to_toml() string {
	return '
[${c.provider.str()}]
base_url: ${c.base_url}
username: ${c.username}
access_token: ${c.access_token}
'
}

pub struct Repository {
pub:
	repo_name string
	ssh_url   string
}

pub fn (repo Repository) str() string {
	return 'Name: ${repo.repo_name}, URL: ${repo.ssh_url}'
}

pub fn parse_repository(map_data map[string]json2.Any) !Repository {
	return Repository{
		repo_name: map_data['name']!.str()
		ssh_url: map_data['ssh_url']!.str()
	}
}
