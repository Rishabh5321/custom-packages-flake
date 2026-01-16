#!/usr/bin/env bash
set -e

# Thorium Update Script
# Adapts logic from update/thorium-update.yaml

# Dependencies: gh, jq, curl, sed, nix

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/thorium/default.nix | head -n 1 || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching latest release from Alex313031/thorium..."
LATEST_TAG=$(gh api repos/Alex313031/thorium/releases/latest --jq .tag_name)

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" == "null" ]; then
    echo "Failed to fetch latest release tag."
    exit 1
fi

LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^M//')
echo "Latest version: $LATEST_VERSION (Tag: $LATEST_TAG)"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Thorium is up-to-date."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

# Check for assets
echo "Checking for assets..."
ASSETS=$(gh api repos/Alex313031/thorium/releases/latest --jq '.assets[].name')
VARIANTS=("AVX" "AVX2" "SSE3" "SSE4")
MISSING=false

for VARIANT in "${VARIANTS[@]}"; do
    EXPECTED="Thorium_Browser_${LATEST_VERSION}_${VARIANT}.AppImage"
    if ! echo "$ASSETS" | grep -q "$EXPECTED"; then
        echo "Missing asset: $EXPECTED"
        MISSING=true
    fi
done

if [ "$MISSING" = "true" ]; then
    echo "Missing required AppImages. Skipping update."
    echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV

# Update version
sed -i "s/$CURRENT_VERSION/$LATEST_VERSION/g" packages/thorium/default.nix

# Update hashes
for VARIANT in "${VARIANTS[@]}"; do
    echo "Processing $VARIANT..."
    DOWNLOAD_URL="https://github.com/Alex313031/thorium/releases/download/${LATEST_TAG}/Thorium_Browser_${LATEST_VERSION}_${VARIANT}.AppImage"
    
    NEW_HASH=$(nix hash file --url "$DOWNLOAD_URL")
    
    if [ -z "$NEW_HASH" ]; then
        echo "Failed to calculate hash for $VARIANT"
        exit 1
    fi
    
    echo "New Hash ($VARIANT): $NEW_HASH"
    
    # Update hash in text
    # Logic: Find the line with the Variant's AppImage, then update the *next* line containing 'hash ='
    sed -i -E "/_${VARIANT}\.AppImage/ { n; s|hash = \".*\";|hash = \"$NEW_HASH\";| }" packages/thorium/default.nix
done

echo "Thorium update complete."
