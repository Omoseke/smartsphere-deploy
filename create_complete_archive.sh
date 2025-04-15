#!/bin/bash

# Script to create a complete archive of the SmartSphere application

echo "Creating complete archive of SmartSphere application..."

# Define the output filename
OUTPUT_FILE="SmartSphere_complete.tar.gz"

# Create the archive, excluding unnecessary files
tar -czvf $OUTPUT_FILE \
  --exclude=".git" \
  --exclude="node_modules" \
  --exclude="$OUTPUT_FILE" \
  --exclude="upload_prep" \
  --exclude="temp_extract" \
  .

# Check if archive was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  size=$(du -h $OUTPUT_FILE | cut -f1)
  echo "✓ Successfully created archive: $OUTPUT_FILE ($size)"
  echo "You can now upload this file to Dropbox."
else
  echo "✗ Failed to create archive"
fi
