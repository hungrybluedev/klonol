module main

import flag
import git
import gitea
import github
import os

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application(name)
	fp.version(version)
	fp.description('$description\n$instructions')
	fp.skip_executable()

	provider_str := fp.string('provider', `p`, 'github', 'git provider to use').to_lower()

	additional_args := fp.finalize() ?

	if additional_args.len > 0 {
		println('Unprocessed arguments: ${additional_args.join(', ')}')
	}

	provider := match provider_str {
		'github' {
			Provider.github
		}
		'gitea' {
			Provider.gitea
		}
		else {
			eprintln('Invalid provider: $provider_str')
			exit(1)
		}
	}

	if !git.git_is_installed() {
		eprintln('Git is not installed. Please install it from a package manager or https://git-scm.com/downloads')
		exit(1)
	}

	credentials := get_credentials_for(provider) ?

	if !git.git_can_use_ssh(credentials.base_url) {
		eprintln('Please setup an SSH Key pair and add the public key to your remote Git server.')
		exit(1)
	}

	repositories := match provider {
		.github {
			github.get_repositories(credentials) ?
		}
		.gitea {
			gitea.get_repositories(credentials) ?
		}
	}

	println(repositories.map(it.str()).join_lines())
	println('Count: $repositories.len')
}
