#!/usr/bin/env bash
set -e

# Update script for Seanime

# Dependencies: curl, jq, nix (for nix-prefetch-url/nix hash)

REPO="5rahim/seanime"
FILE_PATH=$(dirname "$(readlink -f "$0")")/seanime-pkg.nix

echo "Fetching latest release for $REPO..."
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
LATEST_VERSION=$(echo "$RELEASE_JSON" | jq -r .tag_name | sed 's/^v//')

echo "Latest version: $LATEST_VERSION"

# Construct URL
URL="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/seanime-${LATEST_VERSION}_Linux_x86_64.tar.gz"

echo "Prefetching URL: $URL"
# Use nix-prefetch-url to get the sha256 hash
SHA256=$(nix-prefetch-url "$URL")

# Convert to SRI if needed, but simple sha256 is fine. 
# Let's verify if the file uses SRI (sha256-...) or just hex.
# The current file uses SRI "sha256-..."
SRI_HASH=$(nix hash to-sri --type sha256 "$SHA256")

echo "New Hash: $SRI_HASH"

# Update version
sed -i -E "s/version = \"[^\"]+\"/version = \"$LATEST_VERSION\"/" "$FILE_PATH"

# Update hash
sed -i -E "s/hash = \"[^\"]+\"/hash = \"$SRI_HASH\"/" "$FILE_PATH"

echo "Updated seanime to $LATEST_VERSION in $FILE_PATH"
