#!/usr/bin/env bash
set -e

# Helium Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/helium/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/imputnet/helium-linux/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$LATEST_TAG

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Helium is up-to-date."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
    echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV
fi

# Update version
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/helium/default.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/imputnet/helium-linux/releases/download/${LATEST_VERSION}/helium-${LATEST_VERSION}-x86_64.AppImage"
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

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/helium/default.nix

echo "Helium updated."
