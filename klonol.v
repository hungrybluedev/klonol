module main

import gitea
// import github
import os

fn main() {
	base_url := os.getenv_opt('GITEA_BASE_URL') or {
		eprintln('Please set an environment variable GITEA_BASE_URL with the value being the base URL of your Gitea instance.')
		exit(1)
	}

	username := os.getenv_opt('GITEA_USERNAME') or {
		eprintln('Please set an environment variable GITEA_USERNAME with the value being your username.')
		exit(1)
	}

	access_token := os.getenv_opt('GITEA_ACCESS_TOKEN') or {
		eprintln('Please set an environment variable GITEA_ACCESS_TOKEN with the value being your access token.')
		exit(1)
	}

	repositories := gitea.get_repositories(
		base_url: base_url
		username: username
		access_token: access_token
	) or {
		eprintln('Failed to get repositories.')
		eprintln(err)
		exit(1)
	}
	println(repositories.map(it.str()).join_lines())
	println('Count: $repositories.len')
}
