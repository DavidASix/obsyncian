#!/bin/bash
# Set display variable to allow notifications.
export DISPLAY=:0

# Read the configuration file
config_file="$HOME/.config/obsidian_sync.cfg"
if [ -f "$config_file" ]; then
    source "$config_file"
else
    echo "Configuration file not found: $config_file"
    exit 1
fi

# Get the current date in seconds since the Unix epoch
current_date=$(date +%s)

# If the timestamp file exists, read the timestamp from it
if [ -f "$timestamp_file" ]; then
    last_zip_date=$(cat "$timestamp_file")
else
    last_zip_date=0
fi

# Calculate the number of seconds in three days
backup_delay=$(($backup_frequency * 24 * 60 * 60))

# Initialize resync_ran to false
resync_ran=false

# Run the rclone bisync command without --resync
output=$(rclone bisync "$obsidian_folder" "$google_drive")

# If the command failed and the failure includes the term resync, rerun with --resync and set resync_ran to true
if [[ $? -ne 0 ]] && [[ $output == *"resync"* ]]; then
    output=$(rclone bisync "$obsidian_folder" "$google_drive" --resync)
    resync_ran=true
fi

# If the command still failed, send a notification
if [[ $? -ne 0 ]]; then
    if $resync_ran; then
        echo "$output"
        notify-send "Obsidian Sync Error" "An error occurred during synchronization after resync was run:\n$output"
    else
        echo "$output"
        notify-send "Obsidian Sync Error" "An error occurred during synchronization:\n$output"
    fi
else
    # Sync was successful
    # If more than three days have passed since the last zip operation, create a new zip archive
    if ((current_date - last_zip_date >= backup_delay)); then
        zip -r "$backup_location/ObsidianBackup_$(date +%Y%m%d_%H%M%S).zip" "$obsidian_folder"
        # Update the timestamp file with the current date
        echo "$current_date" > "$timestamp_file"
        notify-send "Obsidian Sync Success" "Sync and backup successful"
    else
        notify-send "Obsidian Sync Success" "Sync successful"
    fi
fi