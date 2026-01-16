#!/usr/bin/env bash

set -e

PACKAGE="surge"
OWNER="junaid2005p"
REPO="surge"
NIX_FILE="packages/$PACKAGE/default.nix"

# Fetch latest release version
LATEST_TAG=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | jq -r .tag_name)
LATEST_VERSION=${LATEST_TAG#v}

CURRENT_VERSION=$(grep 'version =' "$NIX_FILE" | cut -d '"' -f 2)

if [ "$LATEST_VERSION" == "$CURRENT_VERSION" ]; then
    echo "No update available. Current: $CURRENT_VERSION, Latest: $LATEST_VERSION"
    exit 0
fi

echo "Update detected: $CURRENT_VERSION -> $LATEST_VERSION"

# Update version in file
sed -i "s/version = \".*\"/version = \"$LATEST_VERSION\"/" "$NIX_FILE"

# Prefetch source
echo "Prefetching source..."
PREFETCH_JSON=$(nix-prefetch-github "$OWNER" "$REPO" --rev "$LATEST_TAG" 2>/dev/null)
NEW_HASH=$(echo "$PREFETCH_JSON" | jq -r .hash)

if [ -z "$NEW_HASH" ] || [ "$NEW_HASH" == "null" ]; then
    echo "Failed to prefetch source hash"
    exit 1
fi

# Update hash
# Use | as delimiter to avoid issues with / in hash
sed -i "s|hash = \".*\"|hash = \"$NEW_HASH\"|" "$NIX_FILE"

# Reset vendorHash to force mismatch
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
sed -i "s|vendorHash = \".*\"|vendorHash = \"$FAKE_HASH\"|" "$NIX_FILE"

# Build to get vendor hash
echo "Building to get vendorHash..."
set +e
BUILD_OUTPUT=$(nix build .#$PACKAGE 2>&1)
set -e

# Extract new vendor hash. Use the last occurrence of "got:" in case there are multiple
NEW_VENDOR_HASH=$(echo "$BUILD_OUTPUT" | grep "got:" | tail -n 1 | awk '{print $2}')

if [ -n "$NEW_VENDOR_HASH" ]; then
    echo "Found vendorHash: $NEW_VENDOR_HASH"
    sed -i "s|vendorHash = \".*\"|vendorHash = \"$NEW_VENDOR_HASH\"|" "$NIX_FILE"
else
    echo "Failed to determine vendorHash"
    echo "$BUILD_OUTPUT"
    exit 1
fi

if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$GITHUB_ENV"
fi
