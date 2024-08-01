#!/bin/bash

# Default configurations
SOURCE_DIR=""
DEST_DIR=""
MODE="oneway"  # Can be 'oneway' or 'twoway'
EXCLUDE_FILE=""
LOG_FILE="sync.log"

# Print usage function
usage() {
    echo "Usage: $0 -s source_dir -d dest_dir -m mode [-e exclude_file] [-l log_file]"
    echo "  -s  Source directory"
    echo "  -d  Destination directory"
    echo "  -m  Synchronization mode (oneway or twoway)"
    echo "  -e  Exclude file with patterns to exclude"
    echo "  -l  Log file"
    exit 1
}

# Parse command line arguments
while getopts "s:d:m:e:l:" opt; do
    case ${opt} in
        s ) SOURCE_DIR="$OPTARG"
            ;;
        d ) DEST_DIR="$OPTARG"
            ;;
        m ) MODE="$OPTARG"
            ;;
        e ) EXCLUDE_FILE="$OPTARG"
            ;;
        l ) LOG_FILE="$OPTARG"
            ;;
        \? ) usage
            ;;
    esac
done

# Validate arguments
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ] || ([ "$MODE" != "oneway" ] && [ "$MODE" != "twoway" ]); then
    usage
fi

# Ensure the source and destination directories exist
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory does not exist: $DEST_DIR"
    exit 1
fi

# Construct rsync options
RSYNC_OPTIONS="-avz --delete"

# Exclude file handling
if [ -n "$EXCLUDE_FILE" ]; then
    if [ ! -f "$EXCLUDE_FILE" ]; then
        echo "Exclude file does not exist: $EXCLUDE_FILE"
        exit 1
    fi
    RSYNC_OPTIONS="$RSYNC_OPTIONS --exclude-from=$EXCLUDE_FILE"
fi

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Handle file conflicts
handle_conflicts() {
    local src_dir="$1"
    local dest_dir="$2"
    local temp_file=$(mktemp)

    # Generate a list of files in source and destination directories
    rsync -avzn --delete "$src_dir/" "$dest_dir/" | grep -E '^deleting' | sed 's/^deleting //' > "$temp_file"

    while read -r file; do
        # Check if file exists in both directories
        if [ -f "$src_dir/$file" ] && [ -f "$dest_dir/$file" ]; then
            src_md5=$(md5sum "$src_dir/$file" | awk '{ print $1 }')
            dest_md5=$(md5sum "$dest_dir/$file" | awk '{ print $1 }')

            # Compare MD5 checksums
            if [ "$src_md5" != "$dest_md5" ]; then
                log "Conflict detected for file: $file"
                # Example conflict resolution: Rename the destination file
                mv "$dest_dir/$file" "$dest_dir/${file}.conflict"
                log "Resolved conflict by renaming destination file: ${file}.conflict"
            fi
        fi
    done < "$temp_file"

    # Clean up temporary file
    rm "$temp_file"
}

# Perform synchronization
if [ "$MODE" == "oneway" ]; then
    # One-way sync from source to destination
    log "Starting one-way synchronization from $SOURCE_DIR to $DEST_DIR"
    rsync $RSYNC_OPTIONS "$SOURCE_DIR/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1
    log "Completed one-way synchronization from $SOURCE_DIR to $DEST_DIR"
elif [ "$MODE" == "twoway" ]; then
    # Two-way sync: sync from source to destination and vice versa
    log "Starting two-way synchronization between $SOURCE_DIR and $DEST_DIR"

    # Handle conflicts before sync
    handle_conflicts "$SOURCE_DIR" "$DEST_DIR"

    # Sync source to destination
    rsync $RSYNC_OPTIONS "$SOURCE_DIR/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1
    log "Completed synchronization from $SOURCE_DIR to $DEST_DIR"

    # Handle conflicts after sync
    handle_conflicts "$DEST_DIR" "$SOURCE_DIR"

    # Sync destination to source
    rsync $RSYNC_OPTIONS "$DEST_DIR/" "$SOURCE_DIR/" >> "$LOG_FILE" 2>&1
    log "Completed synchronization from $DEST_DIR to $SOURCE_DIR"
fi
