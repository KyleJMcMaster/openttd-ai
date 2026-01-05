#!/bin/bash

# Define source and destination
SOURCE_DIR="ai-players/"
DEST_DIR="$HOME/.local/share/openttd/content_download/ai"

# Using -r for recursive and -v for verbose output
cp -rv "$SOURCE_DIR"* "$DEST_DIR"

echo "---------------------------------------"
echo "AI files synced to: $DEST_DIR"

src-engine/build/openttd