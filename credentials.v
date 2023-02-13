module main

import common
import os

fn display_unprotected_access_token_warning() {
	println('\nIMPORTANT: Make sure to clear your terminal history to avoid leaking this
access token. Otherwise, regenerate this token as soon as possible. Also,
consider storing the credentials in a .env file instead. Refer to the
README.md for more instructions.\n')
}

fn get_credentials_for(provider Provider) !common.Credentials {
	return match provider {
		.gitea {
			get_gitea_credentials()!
		}
		.github {
			get_github_credentials()!
		}
	}
}

fn get_github_credentials() !common.Credentials {
	base_url := os.getenv_opt('GITHUB_BASE_URL') or { 'github.com' }

	if base_url.contains('http') {
		return error('Do not include the protocol in the GITHUB_BASE_URL environment variable. Valid example: "git.example.com".')
	}

	username := os.getenv_opt('GITHUB_USERNAME') or {
		eprintln('GITHUB_USERNAME environment variable is not set.')
		username := os.input_opt('Please enter username: ') or {
			return error('Please enter your username.')
		}
		username
	}

	access_token := os.getenv_opt('GITHUB_ACCESS_TOKEN') or {
		eprintln('GITHUB_ACCESS_TOKEN environment variable is not set.')
		display_unprotected_access_token_warning()
		access_token := os.input_opt('Please enter access token: ') or {
			return error('Please enter your access token.')
		}
		access_token
	}

	token_is_valid := common.is_access_token_valid(access_token, 'https://api.github.com/user/issues')

	if !token_is_valid {
		return error('The access token is invalid.')
	}

	return common.Credentials{
		base_url: base_url
		username: username
		access_token: access_token
	}
}

fn get_gitea_credentials() !common.Credentials {
	base_url := os.getenv_opt('GITEA_BASE_URL') or {
		eprintln('GITEA_BASE_URL environment variable is not set.')
		base_url := os.input_opt('Please the base URL (without protocol): ') or {
			return error('Please enter your base URL.')
		}
		base_url
	}

	if base_url.contains('http') {
		return error('Do not include the protocol in the GITEA_BASE_URL environment variable. Valid example: "git.example.com".')
	}

	username := os.getenv_opt('GITEA_USERNAME') or {
		eprintln('GITEA_USERNAME environment variable is not set.')
		username := os.input_opt('Please enter username: ') or {
			return error('Please enter your username.')
		}
		username
	}

	access_token := os.getenv_opt('GITEA_ACCESS_TOKEN') or {
		eprintln('GITEA_ACCESS_TOKEN environment variable is not set.')
		display_unprotected_access_token_warning()
		access_token := os.input_opt('Please enter access token: ') or {
			return error('Please enter your access token.')
		}
		access_token
	}

	token_is_valid := common.is_access_token_valid('unset_value', 'https://${base_url}/api/v1/user?access_token=${access_token}')

	if !token_is_valid {
		return error('The access token is invalid.')
	}

	return common.Credentials{
		base_url: base_url
		username: username
		access_token: access_token
	}
}
