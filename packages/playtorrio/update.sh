#!/usr/bin/env bash
set -e

# Playtorrio Update Script
# Adapts logic from update/playtorrio-update.yaml

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/playtorrio/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api repos/ayman708-UX/PlayTorrio/releases)

LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Playtorrio is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/playtorrio/default.nix

# Calculate Hash
DOWNLOAD_URL="https://github.com/ayman708-UX/PlayTorrio/releases/download/v${LATEST_VERSION}/PlayTorrio.AppImage"
echo "Download URL: $DOWNLOAD_URL"

NEW_HASH=$(nix-prefetch-url --type sha256 "$DOWNLOAD_URL")

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

# nix-prefetch-url returns raw sha256, but nix hash file often implies SRI or base32?
# Actually 'nix-prefetch-url' usually returns base32.
# Let's verify what the previous `hash = ...` expected.
# In the original file: sha256 = "sha256-..." (SRI or base64)
# `nix-prefetch-url` returns base32 by default.
# We can convert it using `nix hash to-sri --type sha256 $NEW_HASH` if needed.
# But often sha256 = "..." accepts the base32 too usually?
# Wait, `nix hash file` output is usually SRI.
# Let's use `nix store prefetch-file --json` to get SRI if possible, or convert.
# Or safer: use curl and nix hash file like the user had.

TEMP_FILE=$(mktemp)
curl -sL "$DOWNLOAD_URL" -o "$TEMP_FILE"
NEW_HASH=$(nix hash file "$TEMP_FILE")
rm -f "$TEMP_FILE"

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s|(sha256\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/playtorrio/default.nix

echo "Playtorrio updated."
