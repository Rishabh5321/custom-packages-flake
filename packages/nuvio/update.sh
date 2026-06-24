#!/usr/bin/env bash
set -e

# Nuvio Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/nuvio/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/aelrased/NuvioDesktop/releases)

# Get the latest tag (excluding drafts)
LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.draft == false)][0].tag_name')

# Extract version from the deb asset name for that tag
LATEST_DEB_NAME=$(echo "$RELEASES" | jq -r "[.[] | select(.tag_name == \"$LATEST_TAG\")][0].assets[] | select(.name | endswith(\"_amd64.deb\")) | .name")
LATEST_VERSION=$(echo "$LATEST_DEB_NAME" | sed -E 's/nuvio_(.*)_amd64.deb/\1/')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag or version."
    exit 1
fi

echo "Latest version: $LATEST_VERSION (tag: $LATEST_TAG)"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Nuvio is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version and tag
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/nuvio/default.nix
sed -i -E "s@(tag\s*=\s*\")[^\"]+@\1${LATEST_TAG}@" packages/nuvio/default.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/aelrased/NuvioDesktop/releases/download/${LATEST_TAG}/nuvio_${LATEST_VERSION}_amd64.deb"
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

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/nuvio/default.nix

echo "Nuvio updated."
