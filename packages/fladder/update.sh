#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"

latestVersion=$(
    gh api repos/DonutWare/Fladder/releases |
        jq -r '[.[] | select(.prerelease == false and .draft == false)][0].tag_name' |
        sed 's/^v//'
)

currentVersion=$(grep -oP 'version\s*=\s*"\K[^"]+' "$PACKAGE_DIR/default.nix")

if [[ -z "$latestVersion" || "$latestVersion" == "null" ]]; then
    echo "Could not determine the latest Fladder version"
    exit 1
fi

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "fladder is up-to-date: $currentVersion"
    exit 0
fi

echo "Updating fladder: $currentVersion -> $latestVersion"

downloadUrl="https://github.com/DonutWare/Fladder/releases/download/v${latestVersion}/Fladder-Linux-${latestVersion}.AppImage"
hashBase32=$(nix-prefetch-url --type sha256 "$downloadUrl" 2>/dev/null | tail -n1)
newHash=$(nix hash convert --hash-algo sha256 --to sri "$hashBase32")

if [[ -z "$newHash" ]]; then
    echo "Failed to calculate hash for $downloadUrl"
    exit 1
fi

sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${latestVersion}@" "$PACKAGE_DIR"/default.nix
sed -i -E "s@(hash\s*=\s*\")[^\"]+@\1${newHash}@" "$PACKAGE_DIR"/default.nix

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

echo "fladder updated to $latestVersion"
