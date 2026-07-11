#!/usr/bin/env bash
set -e

# AlterSend Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/altersend/default.nix || echo "0.0.0")
CURRENT_APPIMAGE_NAME=$(grep -oP 'appimageName\s*=\s*"\K[^"]+' packages/altersend/default.nix || echo "")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/denislupookov/altersend/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
LATEST_APPIMAGE_NAME=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].assets[] | select(.name | endswith(".AppImage") and contains("x86_64")) | .name')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"
echo "Latest AppImage: $LATEST_APPIMAGE_NAME"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ] && [ "$CURRENT_APPIMAGE_NAME" = "$LATEST_APPIMAGE_NAME" ]; then
    echo "AlterSend is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version and appimageName
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/altersend/default.nix
sed -i -E "s@(appimageName\s*=\s*\")[^\"]+@\1${LATEST_APPIMAGE_NAME}@" packages/altersend/default.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/denislupookov/altersend/releases/download/v${LATEST_VERSION}/${LATEST_APPIMAGE_NAME}"
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

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/altersend/default.nix

echo "AlterSend updated."
