#!/usr/bin/env bash
set -e

# ZCode Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/zcode/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching latest version from ZCode site..."
LATEST_VERSION=$(curl -s https://zcode.z.ai/en | grep -oP 'https://cdn-zcode\.z\.ai/zcode/electron/releases/\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)

if [ -z "$LATEST_VERSION" ]; then
    echo "Could not extract valid version from https://zcode.z.ai/en."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "ZCode is up-to-date."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$GITHUB_ENV"
fi

# Update version in default.nix
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/zcode/default.nix

# Calculate Hash
DOWNLOAD_URL="https://cdn-zcode.z.ai/zcode/electron/releases/${LATEST_VERSION}/linux-x64/ZCode-${LATEST_VERSION}-linux-x64.AppImage"
echo "Download URL: $DOWNLOAD_URL"

TEMP_FILE=$(mktemp)
curl -sL "$DOWNLOAD_URL" -o "$TEMP_FILE"
NEW_HASH=$(nix hash file "$TEMP_FILE")
rm -f "$TEMP_FILE"

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/zcode/default.nix

echo "ZCode updated to $LATEST_VERSION."
