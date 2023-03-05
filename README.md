<!--suppress HtmlDeprecatedAttribute -->
<div align="center">
<h1><em>klonol</em></h1>

[vlang.io](https://vlang.io) | [hungrybluedev](https://hungrybluedev.in/)

</div>
<!--suppress HtmlDeprecatedAttribute -->
<div align="center">

[![CI][workflow_badge]][workflow_url]
[![License: MIT][license_badge]][license_url]
[![Git Latest Tag][git_tag_badge]][git_tag_url]

</div>

A phonetic play on the phrase "clone all". It is a CLI tool written in
[V](https://vlang.io/) to clone all repositories belonging to you (or the
authenticated user).

## Features

1. Supports GitHub and [Gitea](https://gitea.io/en-us/).
2. Retrieves information about both public _and_ private repositories belonging
   to the authenticated user.
3. You can list all available repositories, clone them, or run `git pull`
   on existing clones. It uses the user's SSH key to clone.
4. Cross-platform! We've switched to using TOML for storing credentials and
   have tested this project extensively on Windows as well.

## Motivation

I self-host my Gitea instance. It contains several private repositories. There
are some instances where I need to upgrade the server or perform some
maintenance. Although I use [Docker Compose](https://docs.docker.com/compose/)
with mounted volumes to manage the Gitea instance, there may be times when
data retention is not possible. I need to restart my service from scratch. In
order to help with these "from-scratch" scenarios, I wrote this tool.

It allows me to automatically retrieve all of my repositories and clone them
locally. I can stash away a password-protected local copy while I upgrade my
git server in peace.

## Prerequisites

1. You must have Git installed. Use your package manager or navigate to
   [Git's Website](https://git-scm.com/downloads) to download the latest
   version.
2. You must have a GitHub or Gitea account.
3. [Add an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
   to your appropriate account.
4. Generate a [_personal access
   token_](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
   with the minimum scope of `repo` (to allow viewing private repositories)
   and set an expiration of 7 days or the lowest possible. Regenerate this
   key when it expires.

## Installation

### From Source using Git

**Step 1:** Install
[V](https://github.com/vlang/v/blob/master/doc/docs.md#install-from-source)
and [symlink it](https://github.com/vlang/v#symlinking).

If you already have V installed, update your installation by doing `v up`.

**Step 2:** Clone and compile _klonol_

```bash
# Move into a convenient place to install klonol
cd ~/oss/apps

# Clone this repository and move into it
git clone https://github.com/hungrybluedev/klonol.git --depth 1
cd klonol

# Build the executable
v build.vsh
```

The optimized `klonol` binary is saved in the `bin` subdirectory.

**Note:** If you are working on _klonol_ locally and want faster builds for quicker
prototyping, use `v build.vsh -fast` to use TCC and build an unoptimised executable
quickly.

**Step 3:** Add to `PATH`

Add the `bin` subdirectory to your `PATH`. You can edit your `~/.bashrc` file
in Unix-line systems to do this. On Windows, use the system dialog.

**Step 4:** Test installation

Running the following command from any directory should provide a detailed
description on the tool including its name, version, description, and
available options.

```bash
klonol -h
```

## Usage

### Setting the variables

The following variables need to be set in a file called `credentials.toml`.

| Name           | Description                                                                              | Compulsory |
|----------------|------------------------------------------------------------------------------------------|------------|
| `username`     | The GitHub or Gitea username whose repositories are to be queried                        | Yes        |
| `access_token` | The personal access token generated previously                                           | Yes        |
| `base_url`     | The base domain to be used to test SSH and make API calls from. Defaults to `github.com` | For Gitea  |

A sample `credentials.toml` file will look like this:

```toml
[github]
username = "your_username"
access_token = "XYZXYZ"

[gitea]
base_url = "git.yourdomain.com"
username = "your_username"
access_token = "XYZXYZ"

```

### Running klonol

Once the variables have been set, klonol will retrieve the relevant
information automatically.

**Help Information**

```bash
# Get the version
klonol --version
# output:
# klonol 0.5.x


# Get detailed usage information
klonol -h
# OR
klonol --help
# output:
# klonol 0.5.x
# -----------------------------------------------
# Usage: klonol [options] [ARGS]
#
# Description: A CLI tool to "clone all" repositories belonging to you.
#
# klonol requires Access Tokens to work properly. Refer to README for more
# information. It retrieves information about ALL available repositories
# belonging to the authenticated user. Both public and private.
#
# Please follow safety precautions when storing access tokens, and read
# the instructions in README carefully.
#
#
# Options:
#   -p, --provider <string>   git provider to use (default is github)
#   -c, --credentials <string>
#                             path to credentials.toml file (default is ./credentials.toml)
#   -a, --action <string>     action to perform [list, clone, pull]
#   -v, --verbose             enable verbose output
#   -h, --help                display this help and exit
#   --version                 output version information and exit
```

**Sample usage flow for GitHub**

```bash
# Navigate to a directory to store all the repositories in
cd ~/Backups/GitHub

# Make sure you have the proper 'credentials.toml' file in the directory
nano credentials.toml

# List all available repositories
klonol

# Clone all available repositories
klonol --action clone
# OR
klonol -a clone

# ... After some time has passed ...
# Pull all changes from GitHub
klonol -a pull
```

**Sample usage flow for Gitea**

```bash
# Navigate to a directory to store all the repositories in
cd ~/Backups/Gitea

# Make sure you have the proper 'credentials.toml' file in the directory
nano credentials.toml

# List all available repositories
klonol --provider gitea
# OR
klonol -p gitea

# Clone all available repositories
klonol --action clone --provider gitea
# OR
klonol -a clone -p gitea

# ... After some time has passed ...
# Pull all changes from GitHub
klonol -a pull -p gitea
```

### Updating klonol

If you've installed it from source, navigate to the folder where you cloned
the repository. Then run `git pull`. After all the changes have been
downloaded, run `v build.vsh`.

You don't need to change the PATH variable if
klonol is already added to PATH.

## License

This project is distributed under the [MIT License](LICENSE).

[workflow_badge]: https://github.com/hungrybluedev/klonol/actions/workflows/ci.yml/badge.svg

[license_badge]: https://img.shields.io/badge/License-MIT-blue.svg

[workflow_url]: https://github.com/hungrybluedev/klonol/actions/workflows/ci.yml

[license_url]: https://github.com/hungrybluedev/klonol/blob/main/LICENSE

[git_tag_url]: https://github.com/hungrybluedev/klonol/tags

[git_tag_badge]: https://img.shields.io/github/v/tag/hungrybluedev/klonol?color=purple&include_prereleases&sort=semver

## Acknowledgements

 - Thanks to [A1ex-N][a1ex_n] for contributing the [idea][toml_idea] and
[initial code][toml_pr] for supporting cross-platform TOML in favour of
unix-specific ENV!

[a1ex_n]: https://github.com/A1ex-N

[toml_idea]: https://github.com/hungrybluedev/klonol/issues/1

[toml_pr]: https://github.com/hungrybluedev/klonol/pull/2
