#!/usr/bin/env bash
set -e

# AB Download Manager Update Script
# New script following standard patterns

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/ab-download-manager/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/amir1376/ab-download-manager/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "AB Download Manager is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/ab-download-manager/default.nix

# Calculate Hash
# URL format: https://github.com/amir1376/ab-download-manager/releases/download/v1.8.4/ABDownloadManager_1.8.4_linux_x64.tar.gz
DOWNLOAD_URL="https://github.com/amir1376/ab-download-manager/releases/download/v${LATEST_VERSION}/ABDownloadManager_${LATEST_VERSION}_linux_x64.tar.gz"
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

sed -i -E "s|(sha256\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/ab-download-manager/default.nix

echo "AB Download Manager updated."
