module main

import common
import git
import forgejo
import gitea
import github
import mock
import flag
import os

fn is_excluded(full_name string, exclude []string) bool {
	for pattern in exclude {
		if pattern.ends_with('/*') {
			prefix := pattern[..pattern.len - 2]
			if full_name.starts_with('${prefix}/') {
				return true
			}
		} else if full_name == pattern {
			return true
		}
	}
	return false
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application(name)
	fp.version(version)
	fp.description('${description}\n${instructions}')
	fp.skip_executable()

	provider_str :=
		fp.string('provider', `p`, 'github', 'git provider to use (default is github)').to_lower()
	credentials_path := fp.string('credentials', `c`, 'credentials.toml',
		'path to credentials.toml file (default is ./credentials.toml)').to_lower()
	action_str :=
		fp.string('action', `a`, 'list', 'action to perform [list, clone, pull] ').to_lower()
	verbose := fp.bool('verbose', `v`, false, 'enable verbose output')
	use_https := fp.bool('use-https', 0, false, 'clone over HTTPS with access token instead of SSH')

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
			common.Provider.github
		}
		'gitea' {
			common.Provider.gitea
		}
		'forgejo' {
			common.Provider.forgejo
		}
		'mock' {
			common.Provider.mock
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

	credentials := get_credentials_for(provider, credentials_path) or {
		eprintln(err)
		exit(1)
	}

	if action == .clone && !use_https && provider != .mock && !git.can_use_ssh(credentials.base_url) {
		eprintln('Please setup an SSH Key pair and add the public key to your remote Git server.')
		eprintln('Refer to the README for instructions.')
		exit(1)
	}

	mut fetched_repositories := match provider {
		.github {
			github.get_repositories(credentials)!
		}
		.gitea {
			gitea.get_repositories(credentials)!
		}
		.forgejo {
			forgejo.get_repositories(credentials)!
		}
		.mock {
			mock.get_repositories(credentials)!
		}
	}

	if use_https {
		for i, repo in fetched_repositories {
			if repo.clone_url.len > 0 {
				fetched_repositories[i] = common.Repository{
					full_name: repo.full_name
					repo_name: repo.repo_name
					ssh_url:   repo.ssh_url
					clone_url: repo.clone_url.replace('https://',
						'https://${credentials.access_token}@')
					archived:  repo.archived
				}
			}
		}
	}

	// Filter out archived repos and repos matching the denylist (supports "org/*" patterns)
	repositories := fetched_repositories.filter(!it.archived
		&& !is_excluded(it.full_name, credentials.exclude))

	skipped := fetched_repositories.len - repositories.len

	match action {
		.list {
			for repo in repositories {
				println('  "${repo.full_name}",')
			}
			if skipped > 0 {
				println('Count: ${repositories.len} (${skipped} excluded)')
			} else {
				println('Count: ${repositories.len}')
			}
		}
		.clone {
			git.clone_all_repositories(repositories, verbose, use_https) or {
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
