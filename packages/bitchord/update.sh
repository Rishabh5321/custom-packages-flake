#!/usr/bin/env bash
set -e

# BitChord Update Script

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' packages/bitchord/default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching releases from GitHub API..."
RELEASES=$(gh api --paginate --slurp repos/kushagrasinghx/BitChord/releases)

# Only consider stable releases that actually ship a Linux AppImage asset.
LINUX_RELEASE=$(echo "$RELEASES" | jq -r '
  (add // [])
  | map(select(.prerelease == false and .draft == false))
  | map(
      . as $release
      | ([.assets[] | select(.name | test("linux"; "i")) | select(.name | test("\\.AppImage$"; "i"))] | first) as $asset
      | select($asset != null)
      | { tag: $release.tag_name, url: $asset.browser_download_url }
    )
  | first // empty
')

LATEST_TAG=$(echo "$LINUX_RELEASE" | jq -r '.tag // empty')
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
DOWNLOAD_URL=$(echo "$LINUX_RELEASE" | jq -r '.url // empty')

if [ -z "$LATEST_VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "No stable release with a Linux AppImage found; skipping."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

echo "Latest Linux version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "BitChord is up-to-date."
    if [ -n "$GITHUB_ENV" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"

# Update version
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${LATEST_VERSION}@" packages/bitchord/default.nix

# Calculate Hash
echo "Download URL: $DOWNLOAD_URL"

TEMP_FILE=$(mktemp)
curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"
NEW_HASH=$(nix hash file "$TEMP_FILE")
rm -f "$TEMP_FILE"

if [ -z "$NEW_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" packages/bitchord/default.nix

if [ -n "$GITHUB_ENV" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$GITHUB_ENV"
fi

echo "BitChord updated to $LATEST_VERSION."
