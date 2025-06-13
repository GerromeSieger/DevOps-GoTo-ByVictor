#!/bin/bash

# Set the threshold for storage usage (60% in this case)
THRESHOLD=60

# Get the available storage space
AVAILABLE_SPACE=$(df -h / | awk '/\/$/ {print $5}' | sed 's/%//')

# Check if the available space is less than the threshold
if [ "$AVAILABLE_SPACE" -ge "$THRESHOLD" ]; then
    echo "Storage usage is at $AVAILABLE_SPACE%, running docker system prune..."
    docker system prune -f
    docker image prune -f
else
    echo "Storage usage is at $AVAILABLE_SPACE%, no action needed."
fi