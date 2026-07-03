#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq yq-go nix bash common-updater-scripts ripgrep

set -eou pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' default.nix || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching latest release from GitHub API..."
latestVersion=$(
    curl -s https://api.github.com/repos/ayman708-UX/PlayTorrioV2/releases/latest | jq -r '.tag_name' | sed 's/^v//'
)

if [ -z "$latestVersion" ] || [ "$latestVersion" == "null" ]; then
    echo "Could not extract valid release tag."
    exit 1
fi

echo "Latest version: $latestVersion"

if [ "$CURRENT_VERSION" = "$latestVersion" ]; then
    echo "playtorrio-v2 is up-to-date."
    if [ -n "${GITHUB_ENV:-}" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $latestVersion"
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

# Update version in default.nix
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${latestVersion}@" default.nix

# Calculate Hash
echo "Calculating new source hash..."
NEW_SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/ayman708-UX/PlayTorrioV2/archive/refs/tags/v${latestVersion}.tar.gz" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri || true)

if [ -z "$NEW_SRC_HASH" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_SRC_HASH"

# Update hash in default.nix
sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_SRC_HASH}\2|" default.nix

# Generate pubspec.lock.json
curl --fail --silent "https://raw.githubusercontent.com/ayman708-UX/PlayTorrioV2/v${latestVersion}/pubspec.lock" | yq eval --output-format=json --prettyPrint >"$PACKAGE_DIR"/pubspec.lock.json
echo "Generated pubspec.lock.json"

# Generate git-hashes.json
TEMP_CD="$PWD"
while ! test -f flake.nix; do cd ..; done
FLAKE_DIR="$PWD"
cd "$TEMP_CD"

FETCH_SCRIPT=$(nix eval --raw "nixpkgs#dart.fetchGitHashesScript" 2>/dev/null || true)
if [[ -n "$FETCH_SCRIPT" ]]; then
    $FETCH_SCRIPT --input "$PACKAGE_DIR"/pubspec.lock.json --output "$PACKAGE_DIR"/git-hashes.json
    echo "Generated git-hashes.json"
fi

echo "playtorrio-v2 updated successfully."
