#!/usr/bin/env bash
set -e

# Stremio Update Script
# Updates to the latest tag and syncs CEF version from upstream Flatpak configuration

# 1. Fetch latest tag (ignoring 'v' prefix if present)
echo "Fetching latest tag from Stremio/stremio-linux-shell..."
LATEST_TAG=$(gh api repos/Stremio/stremio-linux-shell/tags --jq '.[0].name')
VERSION=${LATEST_TAG#v}

echo "Latest version: $VERSION"

# Use nix eval to get the actual package version safely
CURRENT_VERSION=$(nix eval --raw .#stremio.version)

if [ "$CURRENT_VERSION" == "$VERSION" ]; then
    echo "Stremio is already up to date."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $VERSION"
if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
    echo "LATEST_VERSION=$VERSION" >> $GITHUB_ENV
fi

# 2. Get the COMMIT SHA for this tag
COMMIT_SHA=$(gh api repos/Stremio/stremio-linux-shell/git/ref/tags/${LATEST_TAG} --jq .object.sha)

# 3. Fetch the flatpak manifest to get CEF details
echo "Fetching com.stremio.Stremio.Devel.json for commit $COMMIT_SHA..."
FLATPAK_URL="https://raw.githubusercontent.com/Stremio/stremio-linux-shell/${COMMIT_SHA}/flatpak/com.stremio.Stremio.Devel.json"
FLATPAK_JSON=$(curl -s "$FLATPAK_URL")

# Robust recursive search for the object with name="cef"
CEF_URL=$(echo "$FLATPAK_JSON" | jq -r '.. | select(type == "object" and .name == "cef") | .sources[] | select(.type == "archive") | .url')
CEF_SHA256=$(echo "$FLATPAK_JSON" | jq -r '.. | select(type == "object" and .name == "cef") | .sources[] | select(.type == "archive") | .sha256')

if [ -z "$CEF_URL" ]; then
    echo "Error: Could not find CEF URL in flatpak manifest."
    exit 1
fi

echo "Found CEF URL: $CEF_URL"

# Extract versions from filename
# Pattern: cef_binary_VERSION+gGITREVISION+chromium-CHROMIUMVERSION_linux64_minimal.tar.bz2
# Example: cef_binary_130.0.21+g54811fe+chromium-138.0.7204.101_linux64_minimal.tar.bz2

BASENAME=$(basename "$CEF_URL")
# Remove prefix and suffix
TEMP=${BASENAME#cef_binary_}
TEMP=${TEMP%_linux64_minimal.tar.bz2}

# Split by +
CEF_VERSION=$(echo "$TEMP" | cut -d+ -f1)
GIT_REVISION=$(echo "$TEMP" | cut -d+ -f2 | sed 's/^g//')
CHROMIUM_VERSION=$(echo "$TEMP" | cut -d+ -f3 | sed 's/^chromium-//')

echo "Extracted CEF details:"
echo "  Version: $CEF_VERSION"
echo "  Git Rev: $GIT_REVISION"
echo "  Chrome:  $CHROMIUM_VERSION"
echo "  SHA256:  $CEF_SHA256"

# Convert SHA256 to SRI (because we like SRI)
CEF_SRI=$(nix hash to-sri --type sha256 "$CEF_SHA256")
echo "  SRI:     $CEF_SRI"

# 4. Prefetch source code hash
echo "Prefetching source code..."
SRC_HASH=$(nix-prefetch-github Stremio stremio-linux-shell --rev "${LATEST_TAG}" | jq -r .hash)
echo "  Source Hash: $SRC_HASH"

# 5. Update default.nix using context-aware sed to avoid collisions
FILE="packages/stremio/default.nix"

# Update generic version - target the block with rustPlatform.buildRustPackage
sed -i "/buildRustPackage/,/cargoLock/ s/version = \".*\";/version = \"$VERSION\";/" "$FILE"

# Update source rev
sed -i "s/rev = \".*\";/rev = \"$COMMIT_SHA\";/" "$FILE"

# Update source hash
sed -i "s|sha256 = \".*\";|sha256 = \"$SRC_HASH\";|" "$FILE"

# Update CEF details - target the cefPinned block
sed -i "/cefPinned =/,/srcHashes/ s/version = \".*\";/version = \"$CEF_VERSION\";/" "$FILE"
sed -i "s/gitRevision = \".*\";/gitRevision = \"$GIT_REVISION\";/" "$FILE"
sed -i "s/chromiumVersion = \".*\";/chromiumVersion = \"$CHROMIUM_VERSION\";/" "$FILE"

# Update CEF Hash (x86_64-linux)
sed -i "s|x86_64-linux = \".*\";|x86_64-linux = \"$CEF_SRI\";|" "$FILE"

echo "Update complete!"
