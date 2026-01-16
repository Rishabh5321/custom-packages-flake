#!/usr/bin/env bash
set -e

# Update script for Playtorrio

REPO="ayman708-UX/PlayTorrio"
FILE_PATH=$(dirname "$(readlink -f "$0")")/default.nix

echo "Fetching latest release for $REPO..."
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
LATEST_VERSION=$(echo "$RELEASE_JSON" | jq -r .tag_name | sed 's/^v//')

echo "Latest version: $LATEST_VERSION"

# Construct URL
URL="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/PlayTorrio.AppImage"

echo "Prefetching URL: $URL"
SHA256=$(nix-prefetch-url "$URL")
SRI_HASH=$(nix hash to-sri --type sha256 "$SHA256")

echo "New Hash: $SRI_HASH"

# Update version
sed -i -E "s/version = \"[^\"]+\"/version = \"$LATEST_VERSION\"/" "$FILE_PATH"

# Update hash
sed -i -E "s/sha256 = \"[^\"]+\"/sha256 = \"$SRI_HASH\"/" "$FILE_PATH"

echo "Updated playtorrio to $LATEST_VERSION in $FILE_PATH"
