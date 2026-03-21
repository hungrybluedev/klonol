# Automated Backup Setup

This directory contains a V shell script that automates the full backup workflow:

1. Updates the V compiler and klonol binary
2. Clones new repos and pulls existing ones for each configured provider
3. Creates an encrypted, deduplicated snapshot with restic
4. Prunes old snapshots based on the retention policy

## Prerequisites

On the backup machine:

```bash
# Install system dependencies
sudo apt install git restic

# Install V (one-time)
git clone https://github.com/vlang/v ~/v
cd ~/v && make
sudo ln -sf ~/v/v /usr/local/bin/v

# Download klonol from GitHub releases (the script auto-updates it going forward)
# Visit: https://github.com/hungrybluedev/klonol/releases/latest
# Download the Linux binary, place at /usr/local/bin/klonol, chmod +x
```

## Setup

### 1. Create backup directories

```bash
mkdir -p ~/Backups/GitHub ~/Backups/Forgejo
```

### 2. Copy credentials

Place a `credentials.toml` in each provider directory. See the main
[README](../README.md) for the format.

```bash
# Example for GitHub
cat > ~/Backups/GitHub/credentials.toml << 'EOF'
[github]
username = "your_username"
access_token = "ghp_xxxx"
exclude = [
  "some-org/*",
]
EOF

# Example for Forgejo
cat > ~/Backups/Forgejo/credentials.toml << 'EOF'
[forgejo]
base_url = "forge.yourdomain.com"
username = "your_username"
access_token = "xxxx"
EOF
```

### 3. Set up Backblaze B2

1. Create a **private** bucket in B2 (disable B2-side encryption — restic
   encrypts client-side)
2. Create an **application key** scoped to that bucket with read+write access
3. Note the `keyID` and `applicationKey`

### 4. Configure the backup script

```bash
cp backup.toml.example backup.toml
# Edit backup.toml with your actual values
```

### 5. (Optional) Set up monitoring

If you use [Uptime Kuma](https://github.com/louislam/uptime-kuma), add your
push monitor URL to `backup.toml`:

```toml
[monitoring]
push_url = "https://your-uptime-kuma-instance/api/push/your-token"
```

The script pings this URL after each run with `status=up` on success or
`status=down` on failure, along with the elapsed time. Leave `push_url`
empty (or omit the section) to disable monitoring.

### 6. Initialize the restic repository (one-time)

```bash
export B2_ACCOUNT_ID="your-key-id"
export B2_ACCOUNT_KEY="your-application-key"
export RESTIC_REPOSITORY="b2:your-bucket-name:klonol-backups"
export RESTIC_PASSWORD="your-restic-encryption-password"

restic init
```

**Save the restic password securely.** You need it to restore backups.

### 7. Test run

```bash
v backup.vsh
```

### 8. Install cron job

```bash
crontab -e
```

Add the following line for weekly backups (Sunday at 2 AM):

```
0 2 * * 0 cd /path/to/klonol/backup && /usr/local/bin/v backup.vsh >> ~/klonol-backup.log 2>&1
```

## Restoring from backup

```bash
# List snapshots
export B2_ACCOUNT_ID="..." B2_ACCOUNT_KEY="..." RESTIC_REPOSITORY="..." RESTIC_PASSWORD="..."
restic snapshots

# Restore a specific snapshot
restic restore latest --target ~/Restore/

# Restore a specific snapshot by ID
restic restore abc123 --target ~/Restore/
```

## Retention policy

The default keeps the last 4 snapshots (1 month of weekly backups). Adjust
`retention.keep_last` in `backup.toml` to change this.
