#!/bin/bash

# Configurations
DB_USER="hellal"
DB_PASSWORD="246810"
DB_NAME="hellal"
BACKUP_DIR="/home/hellal/db_backups"
FULL_BACKUP_DIR="$BACKUP_DIR/full"
INCREMENTAL_BACKUP_DIR="$BACKUP_DIR/incremental"
LAST_BACKUP_FILE="$BACKUP_DIR/last_backup.txt"
REMOTE_SERVER="user@remote.server.com"
REMOTE_DIR="/path/to/remote/backup/directory"

# Ensure backup directories exist
mkdir -p "$FULL_BACKUP_DIR"
mkdir -p "$INCREMENTAL_BACKUP_DIR"

# Perform full backup if no previous full backup exists
if [[ ! -f "$LAST_BACKUP_FILE" ]]; then
    echo "Performing initial full backup..."
    FULL_BACKUP_FILE="$FULL_BACKUP_DIR/${DB_NAME}-full-$(date +'%Y-%m-%d-%H-%M-%S').sql.gz"
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$FULL_BACKUP_FILE"
    echo "FULL_BACKUP_FILE=$FULL_BACKUP_FILE" > "$LAST_BACKUP_FILE"
else
    # Perform incremental backup
    echo "Performing incremental backup..."
    LAST_FULL_BACKUP_FILE=$(grep FULL_BACKUP_FILE "$LAST_BACKUP_FILE" | cut -d'=' -f2)
    INCREMENTAL_BACKUP_FILE="$INCREMENTAL_BACKUP_DIR/${DB_NAME}-incremental-$(date +'%Y-%m-%d-%H-%M-%S').sql.gz"
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" --single-transaction --quick --lock-tables=false --flush-logs --master-data=2 --incremental > "$INCREMENTAL_BACKUP_FILE"
    echo "INCREMENTAL_BACKUP_FILE=$INCREMENTAL_BACKUP_FILE" > "$LAST_BACKUP_FILE"
fi

# Upload backup to remote server (optional)
if [[ -n "$REMOTE_SERVER" ]]; then
    echo "Uploading backup to remote server..."
    scp "$INCREMENTAL_BACKUP_FILE" "$REMOTE_SERVER:$REMOTE_DIR"
    if [[ -f "$FULL_BACKUP_FILE" ]]; then
        scp "$FULL_BACKUP_FILE" "$REMOTE_SERVER:$REMOTE_DIR"
    fi
fi

echo "Backup completed successfully!"
