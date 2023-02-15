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
	fp.description('${description}\n${instructions}')
	fp.skip_executable()

	provider_str := fp.string('provider', `p`, 'github', 'git provider to use (default is github)').to_lower()
	credentials_path := fp.string('credentials', `c`, 'credentials.toml', 'path to credentials.toml file (default is ./credentials.toml)').to_lower()
	action_str := fp.string('action', `a`, 'list', 'action to perform [list, clone, pull] ').to_lower()
	verbose := fp.bool('verbose', `v`, false, 'enable verbose output')

	additional_args := fp.finalize() or {
		eprintln(err)
		eprintln(fp.usage())
		exit(1)
	}

	if additional_args.len > 0 {
		eprintln('Unnecessary arguments: ${additional_args.join(', ')}')
		eprintln(fp.usage())
		exit(1)
	}

	provider := match provider_str {
		'github' {
			Provider.github
		}
		'gitea' {
			Provider.gitea
		}
		else {
			eprintln('Invalid provider: ${provider_str}')
			exit(1)
		}
	}

	action := match action_str {
		'list' {
			Action.list
		}
		'clone' {
			Action.clone
		}
		'pull' {
			Action.pull
		}
		else {
			eprintln('Invalid action: ${action_str}')
			exit(1)
		}
	}

	if !git.is_installed() {
		eprintln('Git is not installed. Please install it from a package manager or https://git-scm.com/downloads')
		exit(1)
	}

	credentials := get_credentials_for(provider, credentials_path)!

	if !git.can_use_ssh(credentials.base_url) {
		eprintln('Please setup an SSH Key pair and add the public key to your remote Git server.')
		exit(1)
	}

	repositories := match provider {
		.github {
			github.get_repositories(credentials)!
		}
		.gitea {
			gitea.get_repositories(credentials)!
		}
	}

	match action {
		.list {
			println(repositories.map(it.str()).join_lines())
			println('Count: ${repositories.len}')
		}
		.clone {
			git.clone_all_repositories(repositories, verbose) or {
				eprintln('Failed to clone all repositories.')
				exit(1)
			}
		}
		.pull {
			git.pull_existing_repositories(repositories, verbose) or {
				eprintln('Failed to pull existing repositories.')
				exit(1)
			}
		}
	}
}
