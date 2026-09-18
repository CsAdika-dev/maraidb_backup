#!/bin/bash

#==============================================================================
#TITLE:            backup_mariadb.sh
#DESCRIPTION:      script for automating the periodic mariadb backups on computer
#VERSION:          1.0
#USAGE:            ./backup_mariadb.sh
#==============================================================================

# required: mariadb, mariadbdump, gzip, find

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# CUSTOM SETTINGS
BACKUP_DIR=./backup
IGNORE_DB="(_schema$)"
KEEP_BACKUPS_FOR=7
MARIADBEXTRAFILE="./mariadb.conf"
DUMPOPTIONS="--add-drop-database --events --routines --triggers"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# METHODS
delete_old_backups() {
    echo "Deleting old backup files older than $KEEP_BACKUPS_FOR days..."
    find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +$KEEP_BACKUPS_FOR -delete
}

database_list() {
    local show_databases_sql="SHOW DATABASES WHERE \`Database\` NOT REGEXP '$IGNORE_DB'"
    mariadb --defaults-extra-file="$MARIADBEXTRAFILE" -e "$show_databases_sql" | awk 'NR!=1 {print $1}'
}

backup_database() {
    local database=$1
    local count=$2
    local total=$3
    local db_backup_dir="$BACKUP_DIR/$database"
    local backup_file="$db_backup_dir/$TIMESTAMP.sql.gz"
    
    mkdir -p "$db_backup_dir"
    
    echo "...backing up $count of $total databases: $database"
    
    if mysqldump --defaults-extra-file="$MARIADBEXTRAFILE" $DUMPOPTIONS "$database" | gzip -9 > "$backup_file"; then
        echo "  ✓ $database => $backup_file"
        return 0
    else
        echo "  ✗ ERROR backing up $database" >&2
        return 1
    fi
}

backup_databases() {
    # Retrieve list of databases to backup
    local databases=$(database_list)
    # If no databases are returned, inform the user and exit gracefully
    if [[ -z "$databases" ]]; then
        echo "No databases match the backup criteria. Nothing to backup."
        return 0
    fi

    local total=$(echo $databases | wc -w)
    local count=1
    
    for database in $databases; do
        if ! backup_database "$database" "$count" "$total"; then
            echo "Warning: Failed to backup $database" >&2
        fi
        ((count++))
    done
}

hr() {
    printf '=%.0s' {1..100}
    printf "\n"
}

# RUN SCRIPT
echo "MariaDB Backup started at $TIMESTAMP"
hr
delete_old_backups
hr
backup_databases
hr
echo "All backed up!"
