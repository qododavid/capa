#!/bin/bash

# Define variables
URL="https://github.com/qododavid/capa/releases/download/v1/cover-agent-pro"
DEST_DIR="/tmp/bin"
BINARY_NAME="cover-agent-pro"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Download the binary
wget -P "$DEST_DIR" "$URL"

# Make the binary executable
chmod +x "$DEST_DIR/$BINARY_NAME"

# Confirm completion
echo "Binary downloaded to $DEST_DIR and made executable."
