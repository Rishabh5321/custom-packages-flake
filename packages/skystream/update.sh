#!/usr/bin/env bash
set -e

# SkyStream Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/skystream/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/akashdh11/skystream/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "SkyStream is up-to-date."
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
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/skystream/default.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/akashdh11/skystream/releases/download/v${LATEST_VERSION}/skystream-linux-x64-v${LATEST_VERSION}.tar.gz"
echo "Download URL: $DOWNLOAD_URL"

TEMP_FILE=$(mktemp)
curl -sL "$DOWNLOAD_URL" -o "$TEMP_FILE"
NEW_HASH=$(nix hash file "$TEMP_FILE")
rm -f "$TEMP_FILE"

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

# Convert to SRI if needed (though nix hash file might already return a format sed can use)
# Other scripts use NEW_HASH directly from nix hash file.
# Wait, nix hash file returns sha256-xxx usually.
# Let's make sure it's SRI.
SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")

echo "New Hash: $SRI_HASH"

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${SRI_HASH}\2|" packages/skystream/default.nix

echo "SkyStream updated."
