module common

import x.json2
import strings

pub enum Provider {
	github
	gitea
	forgejo
	mock
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
	username     string @[required]
	access_token string @[required]
	exclude      []string
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
	full_name string
	repo_name string
	ssh_url   string
	clone_url string
	archived  bool
}

pub fn (repo Repository) str() string {
	return '${repo.full_name}'
}

pub fn (repo Repository) effective_url(use_https bool) string {
	if use_https && repo.clone_url.len > 0 {
		return repo.clone_url
	}
	return repo.ssh_url
}

// is_safe_full_name reports whether name is `owner/repo` or `repo` built only from the
// characters GitHub, Gitea and Forgejo allow. full_name becomes a local path, so anything
// else could write outside the working directory.
fn is_safe_full_name(name string) bool {
	segments := name.split('/')
	if segments.len > 2 {
		return false
	}
	for segment in segments {
		if segment in ['', '.', '..'] {
			return false
		}
		for c in segment {
			if !(c.is_alnum() || c == `-` || c == `_` || c == `.`) {
				return false
			}
		}
	}
	return true
}

pub fn parse_repository(map_data map[string]json2.Any) !Repository {
	clone_url := if v := map_data['clone_url'] { v.str() } else { '' }
	full_name := if v := map_data['full_name'] { v.str() } else { map_data['name']!.str() }
	if !is_safe_full_name(full_name) {
		return error('refusing unsafe repository name from the API: ${full_name}')
	}
	archived := if v := map_data['archived'] { v.bool() } else { false }
	return Repository{
		full_name: full_name
		repo_name: map_data['name']!.str()
		ssh_url:   map_data['ssh_url']!.str()
		clone_url: clone_url
		archived:  archived
	}
}
