module main

import common
import os

fn get_credentials_for(provider Provider) ?common.Credentials {
	return match provider {
		.gitea {
			get_gitea_credentials() ?
		}
		.github {
			get_github_credentials() ?
		}
	}
}

fn get_github_credentials() ?common.Credentials {
	base_url := os.getenv_opt('GITHUB_BASE_URL') or { 'github.com' }

	if base_url.contains('http') {
		eprintln('Do not include the protocol in the GITHUB_BASE_URL environment variable. Valid example: "git.example.com".')
		exit(1)
	}

	username := os.getenv_opt('GITHUB_USERNAME') or {
		eprintln('Please set an environment variable GITHUB_USERNAME with the value being your username.')
		exit(1)
	}

	access_token := os.getenv_opt('GITHUB_ACCESS_TOKEN') or {
		eprintln('Please set an environment variable GITHUB_ACCESS_TOKEN with the value being your access token.')
		exit(1)
	}

	return common.Credentials{
		base_url: base_url
		username: username
		access_token: access_token
	}
}

fn get_gitea_credentials() ?common.Credentials {
	base_url := os.getenv_opt('GITEA_BASE_URL') or {
		eprintln('Please set an environment variable GITEA_BASE_URL with the value being the base URL of your Gitea instance. For example: "git.example.com".')
		exit(1)
	}

	if base_url.contains('http') {
		eprintln('Do not include the protocol in the GITEA_BASE_URL environment variable. Valid example: "git.example.com".')
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

	return common.Credentials{
		base_url: base_url
		username: username
		access_token: access_token
	}
}
