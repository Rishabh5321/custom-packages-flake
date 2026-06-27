#!/usr/bin/env bash
set -e

# Stremio Enhanced Update Script

# 1. Fetch current versions/URLs from default.nix
FILE="packages/stremio-enhanced/default.nix"
CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' "$FILE" || echo "0.0.0")
CURRENT_SERVER_URL=$(sed -n '/serverJs = fetchurl [{]/,/[}]/p' "$FILE" | grep -oP 'url\s*=\s*"\K[^"]+')
CURRENT_PLUGIN_URL=$(sed -n '/autoExternalPlayerPlugin = fetchurl [{]/,/[}]/p' "$FILE" | grep -oP 'url\s*=\s*"\K[^"]+')

echo "Current Stremio-Enhanced version: $CURRENT_VERSION"
echo "Current server.js URL:           $CURRENT_SERVER_URL"
echo "Current plugin URL:              $CURRENT_PLUGIN_URL"

# 2. Fetch latest Stremio-Enhanced release
echo "Fetching latest stremio-enhanced release from GitHub API..."
RELEASES=$(gh api repos/REVENGE977/stremio-enhanced/releases)
LATEST_TAG=$(echo "$RELEASES" | jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi
echo "Latest Stremio-Enhanced version: $LATEST_VERSION"

# 3. Fetch latest Stremio server.js version and construct URL
echo "Fetching latest server.js version from Stremio/stremio-service..."
SERVER_VERSION=$(curl -sL https://raw.githubusercontent.com/Stremio/stremio-service/master/Cargo.toml | grep -A 1 '\[package.metadata.server\]' | grep 'version =' | cut -d'"' -f2)
if [ -z "$SERVER_VERSION" ]; then
    echo "Failed to extract server.js version."
    exit 1
fi
LATEST_SERVER_URL="https://dl.strem.io/server/${SERVER_VERSION}/desktop/server.js"
echo "Latest server.js URL:            $LATEST_SERVER_URL"

# 4. Fetch latest auto-external-player.plugin.js Gist URL
echo "Fetching latest plugin URL from Gist..."
LATEST_PLUGIN_URL=$(gh api gists/5e53080b453f9deafb0d250fbc2e8666 | jq -r '.files["auto-external-player.plugin.js"].raw_url')
if [ -z "$LATEST_PLUGIN_URL" ] || [ "$LATEST_PLUGIN_URL" == "null" ]; then
    echo "Failed to retrieve plugin URL."
    exit 1
fi
echo "Latest plugin URL:               $LATEST_PLUGIN_URL"

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

if [ "$CURRENT_PLUGIN_URL" != "$LATEST_PLUGIN_URL" ]; then
    echo "Plugin update detected."
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
    
    DOWNLOAD_URL="https://github.com/REVENGE977/stremio-enhanced/releases/download/v${LATEST_VERSION}/Stremio.Enhanced-${LATEST_VERSION}.AppImage"
    echo "Downloading AppImage to calculate hash: $DOWNLOAD_URL"
    TEMP_FILE=$(mktemp)
    curl -sL "$DOWNLOAD_URL" -o "$TEMP_FILE"
    NEW_HASH=$(nix hash file "$TEMP_FILE")
    rm -f "$TEMP_FILE"
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")
    
    sed -i -E '/src = fetchurl [{]/,/[}]/ s|(hash\s*=\s*\")[^\"]+(\";)|\1'"${SRI_HASH}"'\2|' "$FILE"
fi

if [ "$CURRENT_SERVER_URL" != "$LATEST_SERVER_URL" ]; then
    sed -i -E '/serverJs = fetchurl [{]/,/[}]/ s|(url\s*=\s*\")[^\"]+(\";)|\1'"${LATEST_SERVER_URL}"'\2|' "$FILE"
    
    echo "Downloading server.js to calculate hash: $LATEST_SERVER_URL"
    TEMP_FILE=$(mktemp)
    curl -sL "$LATEST_SERVER_URL" -o "$TEMP_FILE"
    NEW_HASH=$(nix hash file "$TEMP_FILE")
    rm -f "$TEMP_FILE"
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")
    
    sed -i -E '/serverJs = fetchurl [{]/,/[}]/ s|(hash\s*=\s*\")[^\"]+(\";)|\1'"${SRI_HASH}"'\2|' "$FILE"
fi

if [ "$CURRENT_PLUGIN_URL" != "$LATEST_PLUGIN_URL" ]; then
    sed -i -E '/autoExternalPlayerPlugin = fetchurl [{]/,/[}]/ s|(url\s*=\s*\")[^\"]+(\";)|\1'"${LATEST_PLUGIN_URL}"'\2|' "$FILE"
    
    echo "Downloading plugin to calculate hash: $LATEST_PLUGIN_URL"
    TEMP_FILE=$(mktemp)
    curl -sL "$LATEST_PLUGIN_URL" -o "$TEMP_FILE"
    NEW_HASH=$(nix hash file "$TEMP_FILE")
    rm -f "$TEMP_FILE"
    SRI_HASH=$(nix hash convert --hash-algo sha256 --to sri "$NEW_HASH")
    
    sed -i -E '/autoExternalPlayerPlugin = fetchurl [{]/,/[}]/ s|(hash\s*=\s*\")[^\"]+(\";)|\1'"${SRI_HASH}"'\2|' "$FILE"
fi

echo "Stremio Enhanced update complete."
