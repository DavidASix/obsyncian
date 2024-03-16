#!/bin/bash

show_warning() {
    local message="$1"
    zenity --warning --title="Warning" --text="$message"
    echo "Warning: $message" >&2
}

##########################
# Check for dependencies #
##########################

# Zenity
if ! command -v zenity &> /dev/null
then
    echo "Zenity is not installed. Attempting to install..."
    # Check if apt (the package manager) is available
    if command -v apt &> /dev/null
    then
        # Update the package list and install zenity
        sudo apt update
        sudo apt install zenity
    else
        show_warning "Error: Trouble installing zenity. Manual installation of 'zenity' is required."
        exit 1
    fi
else
    echo "Zenity is installed."
fi

# Rclone
if ! command -v rclone &> /dev/null
then
    show_warning "Install rclone 1.58 or later. https://rclone.org/install/"
else
    echo "Rclone is installed."
fi

###############################
# Establish program variables #
###############################
zenity --info \
--text="Welcome to the Obsidian GoogleDrive Sync Tool!\n\n You will be choose your Obsidian folder (where you store your vaults), your backup location (where .zip backups will be stored), and your rclone google drive location."
# Prompt the user for the obsidian folder location
obsidian_folder=$(zenity --file-selection --directory --title="Select Obsidian Folder")

# Check if the obsidian folder location exists
if [ -z "$obsidian_folder" ]; then
  show_warning "No obsidian folder location selected. Exiting."
  exit 1
fi

# Prompt the user for the backup location
backup_location=$(zenity --file-selection --directory --title="Select Backup Location")

# Check if the backup location exists
if [ -z "$backup_location" ]; then
  show_warning "No backup location selected. Exiting."
  exit 1
fi

# Prompt the user for the frequency of backups
backup_frequency=$(zenity --list --title="Select Backup Frequency" --text="Select the frequency in days at which backups should occur" --column="Frequency" --hide-header --width=300 --height=300 --cancel-label="Cancel" --ok-label="OK" --timeout=60 1 2 3 4 5 6 7)


# Check if the user selected a frequency
if [ $? -eq 0 ]; then
  # Convert the selected frequency from a string to an integer
  backup_frequency=$(echo $backup_frequency | awk '{print $1}')
else
  exit 1
fi

# Prompt the user for the frequency of backups
sync_frequency=$(zenity --list --title="Select Backup Frequency" \
    --text="Select the frequency of Syncs in minutes" \
    --column="Frequency" --hide-header --width=300 --height=300 --cancel-label="Cancel" --ok-label="OK" \
    --timeout=60 15 30 60 120 180 240)

if [ $? -eq 0 ]; then
  # Convert the selected frequency from a string to an integer
  sync_frequency=$(echo $sync_frequency | awk '{print $1}')
else
  exit 1
fi

# Prompt the user for the google drive argument
google_drive=$(zenity --entry --title="Enter Google Drive Argument" --text="Enter your Google Drive RClone command and subpath.\n\nIt should look like: \nyour-gdrive-command:folder1/folder2 \n\nIf you're unsure, please consult rclone setup." --width=300 --height=300)

if [ -z "$google_drive" ]; then
  show_warning "Error: Google drive argument is empty. Please enter a valid command."
  exit 1
fi

######################
# Create config file #
######################

# Create the config file
echo "Creating config file..."
touch "$HOME/.config/obsidian_sync.cfg"

# Clear the contents of the config file
echo "" > "$HOME/.config/obsidian_sync.cfg"

# Write the variables to the config file
echo "backup_location=$backup_location" >> "$HOME/.config/obsidian_sync.cfg"
echo "obsidian_folder=$obsidian_folder" >> "$HOME/.config/obsidian_sync.cfg"
echo "google_drive=$google_drive" >> "$HOME/.config/obsidian_sync.cfg"
echo "backup_frequency=$backup_frequency" >> "$HOME/.config/obsidian_sync.cfg"

# Set the timestamp file path
timestamp_file="$backup_location/last_zip_timestamp.txt"
echo "timestamp_file=$timestamp_file" >> "$HOME/.config/obsidian_sync.cfg"

echo "Config file created successfully!"

##########################
# Schedule Job Execution #
##########################

schedule_backup() {
    local sync_frequency="$1"
    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    local command="$script_dir/obsidian-sync.sh"
    local schedule="*/$sync_frequency * * * *"
    echo $command
    crontab -l > crontab.txt
    echo "$schedule $command" >> crontab.txt
    crontab crontab.txt
    rm crontab.txt
}

schedule_backup $sync_frequency