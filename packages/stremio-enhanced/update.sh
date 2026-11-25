#!/usr/bin/env bash
set -e

# Stremio Enhanced Update Script

# 1. Fetch current versions/URLs from default.nix
FILE="packages/stremio-enhanced/default.nix"
CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' "$FILE" || echo "0.0.0")
CURRENT_SERVER_URL=$(sed -n '/serverJs = fetchurl [{]/,/^[[:space:]]*};/p' "$FILE" | grep -oP 'url\s*=\s*"\K[^"]+' || true)

echo "Current Stremio-Enhanced version: $CURRENT_VERSION"
echo "Current server.js URL:           $CURRENT_SERVER_URL"

# 2. Fetch latest Stremio-Enhanced release
# Use `gh api` (authenticated via GITHUB_TOKEN/GH_TOKEN) instead of unauthenticated
# curl, which is easily rate-limited on shared CI runners.
echo "Fetching latest stremio-enhanced release from GitHub API..."
if ! RELEASES=$(gh api repos/REVENGE977/stremio-enhanced/releases); then
    echo "Failed to fetch releases from the GitHub API."
    exit 1
fi
if ! echo "$RELEASES" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "Unexpected GitHub API response (expected a JSON array):"
    echo "$RELEASES"
    exit 1
fi

LATEST_RELEASE=$(echo "$RELEASES" | jq -c '[.[] | select(.prerelease == false and .draft == false)][0]')
LATEST_TAG=$(echo "$LATEST_RELEASE" | jq -r '.tag_name // empty')
LATEST_VERSION=${LATEST_TAG#v}

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi
echo "Latest Stremio-Enhanced version: $LATEST_VERSION"

# Make sure the expected Linux AppImage asset actually exists, otherwise the
# download below would silently hash a 404 page.
APPIMAGE_NAME="Stremio.Enhanced-${LATEST_VERSION}.AppImage"
if ! echo "$LATEST_RELEASE" | jq -e --arg name "$APPIMAGE_NAME" 'any(.assets[]; .name == $name)' >/dev/null 2>&1; then
    echo "Release v${LATEST_VERSION} does not contain asset: ${APPIMAGE_NAME}"
    echo "Available assets:"
    echo "$LATEST_RELEASE" | jq -r '.assets[].name'
    exit 1
fi

# 3. Fetch latest Stremio server.js
# Upstream no longer keeps data/server.js in git (deleted in "build: download
# server file at build time"); it is downloaded from dl.strem.io using the
# version pinned in package.metadata.server.version of Cargo.toml.
echo "Fetching latest server.js version from Stremio/stremio-linux-shell..."
if ! CARGO_TOML=$(gh api repos/Stremio/stremio-linux-shell/contents/Cargo.toml \
        -H 'Accept: application/vnd.github.raw'); then
    echo "Failed to fetch Cargo.toml from the GitHub API."
    exit 1
fi
SERVER_VERSION=$(printf '%s\n' "$CARGO_TOML" \
    | sed -n '/^\[package\.metadata\.server\]/,/^\[/p' \
    | grep -oP 'version\s*=\s*"\K[^"]+' | head -n1 || true)
if [ -z "$SERVER_VERSION" ]; then
    echo "Failed to extract package.metadata.server.version from Cargo.toml."
    exit 1
fi
echo "Latest server.js version:        $SERVER_VERSION"
LATEST_SERVER_URL="https://dl.strem.io/server/${SERVER_VERSION}/desktop/server.js"
echo "Latest server.js URL:            $LATEST_SERVER_URL"



# 5. Check if anything needs updating
ANY_UPDATE=false

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "Stremio-Enhanced update detected: $CURRENT_VERSION -> $LATEST_VERSION"
    ANY_UPDATE=true
fi

if [ "$CURRENT_SERVER_URL" != "$LATEST_SERVER_URL" ]; then
    echo "Stremio server.js update detected."
    ANY_UPDATE=true
fi



if [ "$ANY_UPDATE" = "false" ]; then
    echo "Everything is up-to-date."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> $GITHUB_ENV
    fi
    exit 0
fi

if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> $GITHUB_ENV
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "LATEST_VERSION=$LATEST_VERSION" >> $GITHUB_ENV
    else
        echo "LATEST_VERSION=deps-update-$(date +%Y%m%d)" >> $GITHUB_ENV
    fi
fi

# 6. Apply updates & calculate hashes
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" "$FILE"
    
    DOWNLOAD_URL="https://github.com/REVENGE977/stremio-enhanced/releases/download/v${LATEST_VERSION}/${APPIMAGE_NAME}"
    echo "Downloading AppImage to calculate hash: $DOWNLOAD_URL"
    TEMP_FILE=$(mktemp)
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
        rm -f "$TEMP_FILE"
        echo "Failed to download AppImage: $DOWNLOAD_URL"
        exit 1
    fi
    NEW_HASH=$(nix hash file "$TEMP_FILE")
    rm -f "$TEMP_FILE"
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")
    
    sed -i -E '/src = fetchurl [{]/,/^[[:space:]]*};/ s|(hash\s*=\s*\")[^\"]+(\";)|\1'"${SRI_HASH}"'\2|' "$FILE"
fi

if [ "$CURRENT_SERVER_URL" != "$LATEST_SERVER_URL" ]; then
    sed -i -E '/serverJs = fetchurl [{]/,/^[[:space:]]*};/ s|(url\s*=\s*\")[^\"]+(\";)|\1'"${LATEST_SERVER_URL}"'\2|' "$FILE"
    
    echo "Downloading server.js to calculate hash: $LATEST_SERVER_URL"
    TEMP_FILE=$(mktemp)
    if ! curl -fsSL "$LATEST_SERVER_URL" -o "$TEMP_FILE"; then
        rm -f "$TEMP_FILE"
        echo "Failed to download server.js: $LATEST_SERVER_URL"
        exit 1
    fi
    NEW_HASH=$(nix hash file "$TEMP_FILE")
    rm -f "$TEMP_FILE"
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")
    
    sed -i -E '/serverJs = fetchurl [{]/,/^[[:space:]]*};/ s|(hash\s*=\s*\")[^\"]+(\";)|\1'"${SRI_HASH}"'\2|' "$FILE"
fi



echo "Stremio Enhanced update complete."
