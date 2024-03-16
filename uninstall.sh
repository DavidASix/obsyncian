#!/bin/bash

# Check if the config file exists
if [ -f "$HOME/.config/obsidian_sync.cfg" ]; then
    # Delete the config file
    rm "$HOME/.config/obsidian_sync.cfg"
    echo "Config file deleted successfully!"
else
    echo "Config file not found. Nothing to delete."
fi

# Check if the cron job exists
cron_job=$(crontab -l | grep "obsidian-sync.sh")
if [ -n "$cron_job" ]; then
    # Remove the cron job
    crontab -l | grep -v "obsidian-sync.sh" > crontab.txt
    crontab crontab.txt
    rm crontab.txt
    echo "Cron job deleted successfully!"
else
    echo "Cron job not found. Nothing to delete."
fi