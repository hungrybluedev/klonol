module main

import common
import toml
import os

fn create_default_config(path string) ?common.Credentials {
	if os.exists(path) && os.file_size(path) != 0 {
		return none
	}

	creds := common.Credentials{}
	os.write_file(path, toml.encode(creds)) or {
		return error('Cannot write default config to "${path}"')
	}
	return creds
}

fn get_value_or_set_default(creds toml.Doc, key string, default string) string {
	retrieved_value := (creds.value_opt(key) or { default }).string()
	if retrieved_value == '' {
		return default
	}
	return retrieved_value
}

fn load_config(path string) ?common.Credentials {
	if !os.exists(path) {
		return create_default_config(path) or {
			eprintln(err)
			exit(1)
		}
	}

	creds := toml.parse_file(path) or {
		eprintln('Error parsing config at "${path}". Using default config"')
		exit(1)
	}

	return common.Credentials{
		base_url: get_value_or_set_default(creds, 'BASE_URL', 'github.com')
		username: get_value_or_set_default(creds, 'USERNAME', 'unset_value')
		access_token: get_value_or_set_default(creds, 'ACCESS_TOKEN', 'unset_value')
	}
}

fn display_unprotected_access_token_warning() {
	println('\nIMPORTANT: Make sure to clear your terminal history to avoid leaking this
access token. Otherwise, regenerate this token as soon as possible. Also,
consider storing the credentials in a .toml file instead. Refer to the
README.md for more instructions.\n')
}

fn get_credentials_for(provider Provider, path string) !common.Credentials {
	credentials := load_config(path) or {
		eprintln(err)
		exit(1)
	}
	base_url := credentials.base_url

	if base_url.contains('http') {
		return error('Do not include the protocol in the BASE_URL environment variable. Valid example: "git.example.com".')
	}

	mut username := credentials.username
	if username == 'unset_value' {
		eprintln('USERNAME variable is not set in ${path}.')
		username = os.input_opt('Please enter username: ') or {
			return error('Please enter your username.')
		}
		username
	}

	mut access_token := credentials.access_token
	if access_token == 'unset_value' {
		eprintln('ACCESS_TOKEN variable is not set ${path}.')
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

	return common.Credentials{
		base_url: base_url
		username: username
		access_token: access_token
	}
}
