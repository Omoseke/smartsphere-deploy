#!/bin/bash

# Script to split large files into chunks and upload them to GitHub
# This is useful for files that are too large for GitHub's normal file size limits

FILE="$1"
CHUNK_SIZE=50m  # 50MB chunks
REPO="$2"
TOKEN="$3"

if [ -z "$FILE" ] || [ -z "$REPO" ] || [ -z "$TOKEN" ]; then
  echo "Usage: $0 <file> <repo> <token>"
  echo "Example: $0 SmartSphere.tar.gz biwunor/SmartSphere ghp_YOUR_TOKEN_HERE"
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE not found"
  exit 1
fi

# Create chunk directory
BASENAME=$(basename "$FILE")
CHUNKS_DIR="${BASENAME}_chunks"
mkdir -p "$CHUNKS_DIR"

# Split the file
echo "Splitting $FILE into 50MB chunks..."
split -b $CHUNK_SIZE "$FILE" "$CHUNKS_DIR/${BASENAME}_chunk_"

# Create a manifest file
MANIFEST="$CHUNKS_DIR/manifest.json"
echo "{\"filename\":\"$BASENAME\",\"chunks\":[" > "$MANIFEST"

FIRST=true
for CHUNK in "$CHUNKS_DIR"/${BASENAME}_chunk_*; do
  CHUNK_NAME=$(basename "$CHUNK")
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> "$MANIFEST"
  fi
  echo "  \"$CHUNK_NAME\"" >> "$MANIFEST"
done

echo "]}" >> "$MANIFEST"

# Upload each chunk and the manifest
echo "Uploading chunks to GitHub..."
for CHUNK in "$CHUNKS_DIR"/${BASENAME}_chunk_*; do
  CHUNK_NAME=$(basename "$CHUNK")
  CHUNK_CONTENT=$(base64 -w0 "$CHUNK")
  
  echo "Uploading $CHUNK_NAME..."
  
  json_payload="{\"message\":\"Add chunk $CHUNK_NAME of $BASENAME\",\"content\":\"$CHUNK_CONTENT\",\"branch\":\"chunks\"}"
  
  # Try to create the branch if it doesn't exist
  curl -s -X GET \
    -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$REPO/branches/chunks" >/dev/null 2>&1
  
  if [ $? -ne 0 ]; then
    echo "Creating chunks branch..."
    main_sha=$(curl -s -H "Authorization: token $TOKEN" \
      "https://api.github.com/repos/$REPO/git/refs/heads/main" | \
      grep -o '"sha": "[^"]*' | grep -o '[a-f0-9]\{40\}')
    
    curl -s -X POST \
      -H "Authorization: token $TOKEN" \
      -d "{\"ref\":\"refs/heads/chunks\",\"sha\":\"$main_sha\"}" \
      "https://api.github.com/repos/$REPO/git/refs" >/dev/null
  fi
  
  # Upload the chunk
  curl -s -X PUT \
    -H "Authorization: token $TOKEN" \
    -d "$json_payload" \
    "https://api.github.com/repos/$REPO/contents/$CHUNKS_DIR/$CHUNK_NAME" >/dev/null
    
  if [ $? -eq 0 ]; then
    echo "  ✓ Successfully uploaded $CHUNK_NAME"
  else
    echo "  ✗ Failed to upload $CHUNK_NAME"
  fi
  
  # Wait a bit to avoid rate limiting
  sleep 1
done

# Upload the manifest
MANIFEST_CONTENT=$(base64 -w0 "$MANIFEST")
json_payload="{\"message\":\"Add manifest for $BASENAME chunks\",\"content\":\"$MANIFEST_CONTENT\",\"branch\":\"chunks\"}"

curl -s -X PUT \
  -H "Authorization: token $TOKEN" \
  -d "$json_payload" \
  "https://api.github.com/repos/$REPO/contents/$CHUNKS_DIR/manifest.json" >/dev/null
  
if [ $? -eq 0 ]; then
  echo "✓ Successfully uploaded chunk manifest"
else
  echo "✗ Failed to upload chunk manifest"
fi

echo "Done! File has been split and uploaded to the 'chunks' branch."
echo "To reassemble, download all chunks and use:"
echo "cat ${BASENAME}_chunk_* > $BASENAME"