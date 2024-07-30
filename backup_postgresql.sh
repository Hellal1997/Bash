#!/bin/bash

# Configuration
DB_HOST="localhost"
DB_USER="your_username"
DB_NAME="your_database"
BACKUP_DIR="/home/hellal/backups"
RETENTION_DAYS=7
INCREMENTAL_DIR="$BACKUP_DIR/incremental"
FULL_BACKUP_DIR="$BACKUP_DIR/full"
LAST_FULL_BACKUP_FILE="$BACKUP_DIR/last_full_backup"
CLOUD_STORAGE_BUCKET="your_cloud_bucket"
REMOTE_SERVER="user@remote_server:/path/to/remote/backup/directory"

# Prompt for password securely
echo "Enter the PostgreSQL password:"
read -s DB_PASSWORD

# Export PGPASSWORD for non-interactive password passing
export PGPASSWORD=$DB_PASSWORD

# Create necessary directories
mkdir -p $INCREMENTAL_DIR
mkdir -p $FULL_BACKUP_DIR

# Get current date and time
TIMESTAMP=$(date +"%F-%H-%M-%S")

# Function to perform a full backup
full_backup() {
    BACKUP_FILE="$FULL_BACKUP_DIR/$DB_NAME-full-$TIMESTAMP.sql.gz"
    echo "Starting full backup of database $DB_NAME..."
    pg_dump -h $DB_HOST -U $DB_USER -F c $DB_NAME | gzip > $BACKUP_FILE

    if [ $? -eq 0 ]; then
        echo "Full backup of database $DB_NAME completed successfully!"
        echo $TIMESTAMP > $LAST_FULL_BACKUP_FILE
    else
        echo "Error: Full backup of database $DB_NAME failed!"
        exit 1
    fi
}

# Function to perform an incremental backup
incremental_backup() {
    LAST_FULL_BACKUP=$(cat $LAST_FULL_BACKUP_FILE)
    BACKUP_FILE="$INCREMENTAL_DIR/$DB_NAME-incremental-$TIMESTAMP.sql.gz"
    echo "Starting incremental backup of database $DB_NAME since $LAST_FULL_BACKUP..."
    pg_dump -h $DB_HOST -U $DB_USER -F c -Z 9 $DB_NAME --incremental --last-backup $LAST_FULL_BACKUP | gzip > $BACKUP_FILE

    if [ $? -eq 0 ]; then
        echo "Incremental backup of database $DB_NAME completed successfully!"
    else
        echo "Error: Incremental backup of database $DB_NAME failed!"
        exit 1
    fi
}

# Determine if a full backup is needed
if [ ! -f $LAST_FULL_BACKUP_FILE ]; then
    full_backup
else
    last_full_backup_date=$(cat $LAST_FULL_BACKUP_FILE)
    days_since_last_full_backup=$(( ( $(date -d "$TIMESTAMP" +%s) - $(date -d "$last_full_backup_date" +%s) )/(60*60*24) ))
    
    if [ $days_since_last_full_backup -ge 7 ]; then
        full_backup
    else
        incremental_backup
    fi
fi

# Delete old backups
echo "Deleting backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -exec rm -f {} \;

echo "Old backups deleted successfully!"

# Optional: Upload to a remote server or cloud storage
echo "Uploading backup to remote server..."
scp $BACKUP_FILE $REMOTE_SERVER

echo "Uploading backup to cloud storage..."
# Note: You need to have configured your cloud storage CLI tool (e.g., AWS CLI, GCP CLI) with appropriate permissions
aws s3 cp $BACKUP_FILE s3://$CLOUD_STORAGE_BUCKET/

echo "Backup script completed."

# Unset the password variable for security
unset PGPASSWORD

exit 0
