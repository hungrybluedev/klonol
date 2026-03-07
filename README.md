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

1. Supports GitHub, [Gitea](https://gitea.io/en-us/), and [Forgejo](https://forgejo.org/).
2. Retrieves information about both public _and_ private repositories belonging
   to the authenticated user.
3. You can list all available repositories, clone them, or run `git pull`
   on existing clones. Supports both SSH and HTTPS (with access token) cloning.
4. Exclude repos with a denylist (supports `"org/*"` glob patterns). Archived
   repos are automatically skipped.
5. Cross-platform! We've switched to using TOML for storing credentials and
   have tested this project extensively on Windows as well.

## Motivation

I self-host my Forgejo instance. It contains several private repositories.
There are some instances where I need to upgrade the server or perform some
maintenance. Although I use [Docker Compose](https://docs.docker.com/compose/)
with mounted volumes to manage the instance, there may be times when
data retention is not possible. I need to restart my service from scratch. In
order to help with these "from-scratch" scenarios, I wrote this tool.

It allows me to automatically retrieve all of my repositories and clone them
locally. I can stash away a password-protected local copy while I upgrade my
git server in peace.

## Prerequisites

1. You must have Git installed. Use your package manager or navigate to
   [Git's Website](https://git-scm.com/downloads) to download the latest
   version.
2. You must have a GitHub, Gitea, or Forgejo account.
3. If cloning over SSH, [add an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
   to your appropriate account. If cloning over HTTPS, SSH keys are not required.
4. Generate a personal access token (see instructions below).

### Generating Access Tokens

#### GitHub

1. Go to [github.com](https://github.com) -> Avatar (top-right) -> **Settings**
2. Scroll to **Developer settings** (bottom of left sidebar)
3. **Personal access tokens** -> **Tokens (classic)**
4. **Generate new token** -> **Generate new token (classic)**
5. Name: `klonol-backup`, Expiration: 90 days (or your preference)
6. Scopes: check **`repo`** (full control of private repositories)
7. Click **Generate token** and copy it immediately

Use a _classic_ token (not fine-grained) if you want access to organization
repos you belong to.

#### Gitea

1. Go to your Gitea instance -> Avatar (top-right) -> **Settings**
2. **Applications** tab
3. Under "Generate New Token", enter a name and select scopes:
   **read:repository** and **read:user** at minimum
4. Click **Generate Token** and copy it immediately

#### Forgejo

1. Go to your Forgejo instance -> Avatar (top-right) -> **Settings**
2. **Applications** tab
3. Under "Manage Access Tokens", enter a name (e.g. `klonol-backup`)
4. Set **Repository and Organization Access** to "All (public, private, and limited)"
5. Select permissions: **repository: Read** and **user: Read** at minimum
6. Click **Generate Token** and copy it immediately

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

| Name           | Description                                                                               | Compulsory        |
| -------------- | ----------------------------------------------------------------------------------------- | ----------------- |
| `username`     | The GitHub, Gitea, or Forgejo username whose repositories are to be queried               | Yes               |
| `access_token` | The personal access token generated previously                                            | Yes               |
| `base_url`     | The base domain to be used to test SSH and make API calls from. Defaults to `github.com`  | For Gitea/Forgejo |
| `exclude`      | List of repos to skip. Supports exact names (`"user/repo"`) and glob patterns (`"org/*"`) | No                |

Archived repositories are automatically excluded.

A sample `credentials.toml` file will look like this:

```toml
[github]
username = "your_username"
access_token = "XYZXYZ"
exclude = [
  "some-org/*",
  "your_username/old-repo",
]

[gitea]
base_url = "git.yourdomain.com"
username = "your_username"
access_token = "XYZXYZ"

[forgejo]
base_url = "forge.yourdomain.com"
username = "your_username"
access_token = "XYZXYZ"
```

To build your exclude list, first run `klonol` (or `klonol -p forgejo`) to
list all available repositories. The output is formatted so you can copy
entries directly into the `exclude` array.

### Running klonol

Once the variables have been set, klonol will retrieve the relevant
information automatically.

**Help Information**

```bash
# Get the version
klonol --version
# output:
# klonol 0.6.x


# Get detailed usage information
klonol -h
# OR
klonol --help
# output:
# klonol 0.6.x
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
#   --use-https               clone over HTTPS with access token instead of SSH
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
# Pull all changes from Gitea
klonol -a pull -p gitea
```

**Sample usage flow for Forgejo**

```bash
# Navigate to a directory to store all the repositories in
cd ~/Backups/Forgejo

# Make sure you have the proper 'credentials.toml' file in the directory
nano credentials.toml

# List all available repositories
klonol --provider forgejo
# OR
klonol -p forgejo

# Clone all available repositories
klonol --action clone --provider forgejo
# OR
klonol -a clone -p forgejo

# ... After some time has passed ...
# Pull all changes from Forgejo
klonol -a pull -p forgejo
```

**Cloning over HTTPS (instead of SSH)**

If you prefer HTTPS cloning (or don't have SSH keys set up), use the
`--use-https` flag. The access token is automatically embedded in the
clone URL for authentication.

```bash
# Clone all GitHub repos over HTTPS
klonol -a clone --use-https

# Clone all Forgejo repos over HTTPS
klonol -a clone -p forgejo --use-https
```

### Updating klonol

If you've installed it from source, navigate to the folder where you cloned
the repository. Then run `git pull`. After all the changes have been
downloaded, run `v build.vsh`.

You don't need to change the PATH variable if
klonol is already added to PATH.

## Automated Backups

klonol includes a V shell script for fully automated backups with
[restic](https://restic.net/) and [Backblaze B2](https://www.backblaze.com/cloud-storage).
It handles updating klonol, cloning/pulling all repos, creating encrypted
deduplicated snapshots, and pruning old backups — all via a weekly cron job.

See [backup/README.md](backup/README.md) for setup instructions.

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
