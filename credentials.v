module main

import common
import toml
import os

fn create_default_config(provider common.Provider, path string) !common.Credential {
	if os.exists(path) && os.file_size(path) != 0 {
		return error('Credential file already exists.')
	}

	credential := common.Credential{
		provider: provider
		username: 'unset_value'
		access_token: 'unset_value'
	}
	file := common.CredentialFile{
		credentials: [credential]
	}
	os.write_file(path, file.to_toml()) or {
		return error('Cannot write default config to "${path}"')
	}
	return credential
}

fn load_config(provider common.Provider, path string) !common.Credential {
	if !os.exists(path) {
		return create_default_config(provider, path)!
	}

	cred_file := toml.parse_file(path) or {
		return error('Error parsing config at "${path}". Using default config"')
	}

	credential := cred_file.value_opt(provider.str()) or {
		return error('Could not read the credentials for ${provider}')
	}

	return common.Credential{
		provider: provider
		base_url: (credential.value_opt('base_url') or { toml.Any('github.com') }).string()
		username: (credential.value_opt('username') or {
			return error('username not provided for ${provider}')
		}).string()
		access_token: (credential.value_opt('access_token') or {
			return error('access_token not provided ')
		}).string()
	}
}

fn display_unprotected_access_token_warning() {
	println('\nIMPORTANT: Make sure to clear your terminal history to avoid leaking this
access token. Otherwise, regenerate this token as soon as possible. Also,
consider storing the credentials in a .toml file instead. Refer to the
README.md for more instructions.\n')
}

fn get_credentials_for(provider common.Provider, path string) !common.Credential {
	credentials := load_config(provider, path)!
	base_url := credentials.base_url

	if base_url.contains('http') || base_url.contains('://') {
		return error('Do not include the protocol in the base_url variable. Valid example: "git.example.com".')
	}

	mut username := credentials.username
	if username == 'unset_value' {
		eprintln('username variable is not set in ${path}.')
		username = os.input_opt('Please enter username: ') or {
			return error('Please enter your username.')
		}
		username
	}

	mut access_token := credentials.access_token
	if access_token == 'unset_value' {
		eprintln('access_token variable is not set ${path}.')
		display_unprotected_access_token_warning()
		access_token = os.input_opt('Please enter access token: ') or {
			return error('Please enter your access token.')
		}
		access_token
	}

	token_is_valid := match provider {
		.github { common.is_access_token_valid(access_token, 'https://api.github.com/user/issues') }
		.gitea { common.is_access_token_valid(access_token, 'https://${base_url}/api/v1/user?access_token=${access_token}') }
	}

	if !token_is_valid {
		return error('The access token is invalid.')
	}

	return common.Credential{
		provider: provider
		base_url: base_url
		username: username
		access_token: access_token
	}
}
