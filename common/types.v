module common

import x.json2

pub struct Credentials {
pub:
	base_url     string = 'github.com'
	username     string
	access_token string = 'unset value'
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
