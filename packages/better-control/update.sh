#!/usr/bin/env bash
set -e

# Better Control Update Script
# Adapts logic from update/better-contol-update.yaml

CURRENT_SHA=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/better-control/default.nix || echo "0000000000000000000000000000000000000000")
echo "Current SHA: $CURRENT_SHA"

echo "Fetching latest commit SHA from main..."
LATEST_SHA=$(gh api repos/better-ecosystem/better-control/commits/main --jq '.sha')

if [ -z "$LATEST_SHA" ] || [ "$LATEST_SHA" == "null" ]; then
    echo "Could not extract latest commit SHA."
    exit 1
fi

echo "Latest SHA: $LATEST_SHA"

if [ "$CURRENT_SHA" = "$LATEST_SHA" ]; then
    echo "Better Control is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_SHA -> $LATEST_SHA"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_SHA" >> $GITHUB_ENV

# Update version (rev)
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_SHA}@" packages/better-control/default.nix

# Calculate Hash using nix-prefetch-github
# Alternatively, since we are in a nix environment, we can use nix-prefetch-url or similar if available.
# But following the script, we'll try to use nix-prefetch-github if it's installed, or fallback to nix-prefetch-url with unpack?
# Actually, since it's fetchFromGitHub, we need the hash of the unpacked source.

# The workflow adds nix-prefetch-github to the packages.
# But for local testing, we assume it's there or we fail.
# Let's rely on nix-prefetch-github as per the reference script.

echo "Prefetching..."
PREFETCH_JSON=$(nix-prefetch-github better-ecosystem better-control --rev "$LATEST_SHA" 2>/dev/null)
NEW_HASH=$(echo "$PREFETCH_JSON" | jq -r .hash)

if [ -z "$NEW_HASH" ] || [ "$NEW_HASH" == "null" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/better-control/default.nix

echo "Better Control updated."
