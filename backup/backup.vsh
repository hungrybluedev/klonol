import toml
import net.http
import x.json2
import time

// --- Helpers ---

fn log_msg(msg string) {
	t := time.now()
	println('[${t.format_ss()}] ${msg}')
}

fn run_cmd(cmd string) (int, string) {
	log_msg('Running: ${cmd}')
	result := execute(cmd)
	if result.exit_code != 0 {
		log_msg('FAILED (exit ${result.exit_code}): ${result.output}')
	}
	return result.exit_code, result.output
}

fn run_cmd_must(cmd string) string {
	code, output := run_cmd(cmd)
	if code != 0 {
		log_msg('FATAL: command failed, aborting.')
		exit(1)
	}
	return output
}

fn capitalize_provider(provider string) string {
	if provider.len == 0 {
		return provider
	}
	return provider[0..1].to_upper() + provider[1..]
}

// --- Config ---

struct ProviderEntry {
	name string
	dir  string
}

struct Config {
	backup_root string
	klonol_bin  string
	klonol_repo string
	restic_repo string
	restic_pass string
	b2_id       string
	b2_key      string
	keep_last   int
	push_url    string
	providers   []ProviderEntry
}

fn load_config() Config {
	script_dir := dir(@FILE)
	config_path := join_path(script_dir, 'backup.toml')

	if !exists(config_path) {
		log_msg('FATAL: ${config_path} not found. Copy backup.toml.example to backup.toml and fill in values.')
		exit(1)
	}

	doc := toml.parse_file(config_path) or {
		log_msg('FATAL: failed to parse ${config_path}: ${err}')
		exit(1)
	}

	names_raw := doc.value('providers.list').array()
	dirs_raw := doc.value('providers.dirs').array()
	mut providers := []ProviderEntry{}
	for i, p in names_raw {
		d := if i < dirs_raw.len { dirs_raw[i].string() } else { capitalize_provider(p.string()) }
		providers << ProviderEntry{
			name: p.string()
			dir:  d
		}
	}

	return Config{
		backup_root: doc.value_opt('paths.backup_root') or { toml.Any('') }.string()
		klonol_bin:  doc.value_opt('paths.klonol_bin') or { toml.Any('/usr/local/bin/klonol') }.string()
		klonol_repo: doc.value_opt('paths.klonol_repo') or { toml.Any('hungrybluedev/klonol') }.string()
		restic_repo: doc.value_opt('restic.repository') or { toml.Any('') }.string()
		restic_pass: doc.value_opt('restic.password') or { toml.Any('') }.string()
		b2_id:       doc.value_opt('b2.account_id') or { toml.Any('') }.string()
		b2_key:      doc.value_opt('b2.account_key') or { toml.Any('') }.string()
		keep_last:   doc.value_opt('retention.keep_last') or { toml.Any(4) }.int()
		push_url:    doc.value_opt('monitoring.push_url') or { toml.Any('') }.string()
		providers:   providers
	}
}

// --- Validation ---

fn validate(config Config) {
	if config.backup_root.len == 0 {
		log_msg('FATAL: paths.backup_root is not set')
		exit(1)
	}
	if config.restic_repo.len == 0 {
		log_msg('FATAL: restic.repository is not set')
		exit(1)
	}
	if config.restic_pass.len == 0 {
		log_msg('FATAL: restic.password is not set')
		exit(1)
	}
	if config.b2_id.len == 0 || config.b2_key.len == 0 {
		log_msg('FATAL: b2.account_id and b2.account_key must be set')
		exit(1)
	}
	if config.providers.len == 0 {
		log_msg('FATAL: providers.list is empty')
		exit(1)
	}

	for tool in ['git', 'restic'] {
		find_abs_path_of_executable(tool) or {
			log_msg('FATAL: ${tool} is not installed or not in PATH')
			exit(1)
		}
	}
}

// --- Update klonol ---

fn get_installed_version(klonol_bin string) string {
	if !exists(klonol_bin) {
		return ''
	}
	result := execute('${klonol_bin} --version')
	if result.exit_code != 0 {
		return ''
	}
	// Output is like "klonol 0.7.0\n..."
	first_line := result.output.trim_space().split('\n')[0] or { return '' }
	parts := first_line.split(' ')
	if parts.len >= 2 {
		return parts[1].trim_space()
	}
	return ''
}

fn update_klonol(config Config) {
	log_msg('Checking for klonol updates...')

	api_url := 'https://api.github.com/repos/${config.klonol_repo}/releases/latest'
	resp := http.get(api_url) or {
		log_msg('WARNING: could not check for updates: ${err}')
		return
	}
	if resp.status_code != 200 {
		log_msg('WARNING: GitHub API returned ${resp.status_code}, skipping update check')
		return
	}

	data := json2.decode[json2.Any](resp.body) or {
		log_msg('WARNING: could not parse GitHub API response: ${err}')
		return
	}
	release_map := data.as_map()
	tag := release_map['tag_name'] or {
		log_msg('WARNING: no tag_name in release response')
		return
	}
	latest_version := tag.str().trim_left('v')
	installed_version := get_installed_version(config.klonol_bin)

	log_msg('Installed: ${if installed_version.len > 0 { installed_version } else { '(not found)' }}, Latest: ${latest_version}')

	if installed_version == latest_version {
		log_msg('klonol is up to date.')
		return
	}

	// Find the ubuntu zip in release assets (assets are named klonol-ubuntu.zip, etc.)
	assets := (release_map['assets'] or {
		log_msg('WARNING: no assets in release')
		return
	}).as_array()

	mut download_url := ''
	for asset in assets {
		asset_map := asset.as_map()
		name := (asset_map['name'] or { continue }).str()
		if name.contains('ubuntu') {
			download_url = (asset_map['browser_download_url'] or { continue }).str()
			break
		}
	}

	if download_url.len == 0 {
		log_msg('WARNING: no Linux binary found in release assets')
		return
	}

	log_msg('Downloading klonol ${latest_version} from ${download_url}...')

	// Download zip, extract binary, and install
	tmp_dir := join_path(temp_dir(), 'klonol_update')
	rmdir_all(tmp_dir) or {}
	mkdir_all(tmp_dir) or {
		log_msg('WARNING: failed to create temp dir: ${err}')
		return
	}

	zip_path := join_path(tmp_dir, 'klonol.zip')
	dl_result := execute('curl -sL -o ${zip_path} ${download_url}')
	if dl_result.exit_code != 0 {
		log_msg('WARNING: download failed: ${dl_result.output}')
		rmdir_all(tmp_dir) or {}
		return
	}

	unzip_result := execute('unzip -o ${zip_path} -d ${tmp_dir}')
	if unzip_result.exit_code != 0 {
		log_msg('WARNING: unzip failed: ${unzip_result.output}')
		rmdir_all(tmp_dir) or {}
		return
	}

	extracted_bin := join_path(tmp_dir, 'klonol')
	if !exists(extracted_bin) {
		log_msg('WARNING: extracted binary not found at ${extracted_bin}')
		rmdir_all(tmp_dir) or {}
		return
	}

	cp(extracted_bin, config.klonol_bin) or {
		log_msg('WARNING: failed to copy binary: ${err}')
		rmdir_all(tmp_dir) or {}
		return
	}
	chmod(config.klonol_bin, 0o755) or {
		log_msg('WARNING: failed to chmod: ${err}')
		rmdir_all(tmp_dir) or {}
		return
	}
	rmdir_all(tmp_dir) or {}

	log_msg('Updated klonol to ${latest_version}.')
}

// --- Update V ---

fn update_v() {
	log_msg('Updating V compiler...')
	code, _ := run_cmd('${quoted_path(@VEXE)} up')
	if code != 0 {
		log_msg('WARNING: v up failed, continuing with current version')
	}
}

// --- Clone and Pull ---

fn sync_providers(config Config) int {
	mut failures := 0
	old_dir := getwd()

	for entry in config.providers {
		target := join_path(config.backup_root, entry.dir)

		if !exists(target) {
			log_msg('WARNING: ${target} does not exist, skipping ${entry.name}')
			failures++
			continue
		}

		log_msg('--- Syncing ${entry.name} (${target}) ---')
		chdir(target) or {
			log_msg('WARNING: could not chdir to ${target}: ${err}')
			failures++
			continue
		}

		// Clone new repos
		clone_code, _ := run_cmd('${config.klonol_bin} -p ${entry.name} -a clone --use-https')
		if clone_code != 0 {
			log_msg('WARNING: clone failed for ${entry.name}')
			failures++
		}

		// Pull existing repos
		pull_code, _ := run_cmd('${config.klonol_bin} -p ${entry.name} -a pull --use-https -v')
		if pull_code != 0 {
			log_msg('WARNING: pull failed for ${entry.name}')
			failures++
		}
	}

	chdir(old_dir) or {}
	return failures
}

// --- Restic Backup ---

fn restic_backup(config Config) int {
	mut failures := 0

	// Set environment variables for restic
	setenv('B2_ACCOUNT_ID', config.b2_id, true)
	setenv('B2_ACCOUNT_KEY', config.b2_key, true)
	setenv('RESTIC_REPOSITORY', config.restic_repo, true)
	setenv('RESTIC_PASSWORD', config.restic_pass, true)

	// Build list of backup paths
	mut backup_paths := []string{}
	for entry in config.providers {
		p := join_path(config.backup_root, entry.dir)
		if exists(p) {
			backup_paths << p
		}
	}

	if backup_paths.len == 0 {
		log_msg('WARNING: no backup paths found')
		return 1
	}

	paths_str := backup_paths.join(' ')
	tag := time.now().custom_format('YYYY-MM-DD')

	log_msg('--- Running restic backup ---')
	code, _ := run_cmd('restic backup ${paths_str} --tag klonol-${tag} --exclude .DS_Store')
	if code != 0 {
		log_msg('ERROR: restic backup failed')
		failures++
	}

	log_msg('--- Running restic forget + prune (keep last ${config.keep_last}) ---')
	forget_code, _ := run_cmd('restic forget --keep-last ${config.keep_last} --prune')
	if forget_code != 0 {
		log_msg('ERROR: restic forget/prune failed')
		failures++
	}

	return failures
}

// --- Monitoring ---

fn push_status(config Config, status string, msg string, elapsed time.Duration) {
	if config.push_url.len == 0 {
		return
	}
	ping_secs := int(elapsed / time.second)
	url := '${config.push_url}?status=${status}&msg=${msg}&ping=${ping_secs}'
	http.get(url) or {
		log_msg('WARNING: failed to push status to monitoring: ${err}')
		return
	}
	log_msg('Pushed status "${status}" to monitoring.')
}

// --- Main ---

log_msg('=== klonol backup started ===')
start := time.now()

config := load_config()
validate(config)

update_v()
update_klonol(config)

sync_failures := sync_providers(config)
restic_failures := restic_backup(config)

total_failures := sync_failures + restic_failures
elapsed := time.since(start)
log_msg('=== Backup completed in ${elapsed} with ${total_failures} failure(s) ===')

if total_failures > 0 {
	push_status(config, 'down', '${total_failures}+failures', elapsed)
	exit(1)
} else {
	push_status(config, 'up', 'OK', elapsed)
}
