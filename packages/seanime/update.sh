#!/usr/bin/env bash
set -e

# Seanime Update Script
# Adapts logic from update/seanime.yaml

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/seanime/seanime-pkg.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching latest release from GitHub AGPI..."
RELEASES=$(gh api repos/5rahim/seanime/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Seanime is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/seanime/seanime-pkg.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/5rahim/seanime/releases/download/v${LATEST_VERSION}/seanime-${LATEST_VERSION}_Linux_x86_64.tar.gz"
echo "Download URL: $DOWNLOAD_URL"

NEW_HASH=$(nix hash file --url "$DOWNLOAD_URL")

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/seanime/seanime-pkg.nix

echo "Seanime updated."
