# MariaDB Backup Script

This Bash script automates periodic backups of MariaDB databases. Each database is exported to a compressed SQL dump, stored in its own directory, and old backup files are removed automatically.

## Features

- Automatically discovers MariaDB databases.
- Excludes databases matching the configured ignore pattern.
- Stores each database backup in a separate directory.
- Includes tables, data, events, routines, and triggers in the dump.
- Compresses SQL dumps using `gzip -9`.
- Removes `.sql.gz` backup files older than the configured retention period.
- Uses Bash strict mode with `set -euo pipefail`.

## Requirements

The following commands must be available on the system running the script:

- Bash
- MariaDB client (`mariadb`)
- `mysqldump`
- `gzip`
- `find`
- `awk`

You can check the dependencies with:

```bash
command -v mariadb mysqldump gzip find awk
```

## Configuration

The script reads MariaDB connection details from an option file. Use the following format:

```ini
[client]
user="backup_user"
password="your-password"
host="127.0.0.1"
port="3306"
```

> **Security:** Protect this file because it may contain the database password.

```bash
chmod 600 mariadb.cnf
```

### Configuration filename

The script currently looks for:

```bash
MARIADBEXTRAFILE="./mariadb.conf"
```

The repository configuration file is named `mariadb.cnf`. Either rename it:

```bash
mv mariadb.cnf mariadb.conf
```

or update the `MARIADBEXTRAFILE` variable in `backup_mariadb.sh` to:

```bash
MARIADBEXTRAFILE="./mariadb.cnf"
```

## Installation

Clone the repository and enter its directory:

```bash
git clone https://github.com/CsAdika-dev/maraidb_backup.git
cd maraidb_backup
```

Make the script executable:

```bash
chmod +x backup_mariadb.sh
```

Configure the MariaDB option file before running the script.

## Usage

Run the script from the directory containing the script and the MariaDB option file:

```bash
./backup_mariadb.sh
```

The default backup directory is `./backup`. Backups are organized as follows:

```text
backup/
├── database_1/
│   └── 2026-01-01_12-30-00.sql.gz
└── database_2/
    └── 2026-01-01_12-30-00.sql.gz
```

Backup filenames use the following format:

```text
YYYY-MM-DD_HH-MM-SS.sql.gz
```

## Script Settings

The following variables can be changed near the beginning of `backup_mariadb.sh`:

| Variable | Default value | Description |
|---|---|---|
| `BACKUP_DIR` | `./backup` | Directory where backups are stored. |
| `IGNORE_DB` | `(_schema$)` | Regular expression for databases to exclude. |
| `KEEP_BACKUPS_FOR` | `7` | Number of days to keep backup files. |
| `MARIADBEXTRAFILE` | `./mariadb.conf` | Path to the MariaDB option file. |
| `DUMPOPTIONS` | `--add-drop-database --events --routines --triggers` | Options passed to `mysqldump`. |

For example, to keep backups for 30 days:

```bash
KEEP_BACKUPS_FOR=30
```

## Automated Backups with Cron

Open the current user's crontab:

```bash
crontab -e
```

The following example runs the backup every day at 02:00:

```cron
0 2 * * * cd /opt/maraidb_backup && /opt/maraidb_backup/backup_mariadb.sh >> /var/log/mariadb-backup.log 2>&1
```

Use absolute paths in cron jobs because cron may run commands from a different working directory.

## Restoring a Backup

To restore a compressed backup, use:

```bash
gunzip -c backup/database_1/2026-01-01_12-30-00.sql.gz | mariadb --defaults-extra-file=./mariadb.cnf
```

Replace the path and filename with the backup you want to restore.

> **Warning:** The dump uses the `--add-drop-database` option. During restoration, the target database may be dropped and recreated. Always verify the backup and target environment before importing it.

## Security Recommendations

- Never commit a real password to a public repository.
- Use a MariaDB user with only the permissions required for backups.
- Restrict permissions on the option file and backup directory.
- Store backups on a separate disk or remote system when possible.
- Regularly test restoration procedures.
- Monitor the backup output and verify that expected backup files are created.

## License

This repository does not currently include a license file.
