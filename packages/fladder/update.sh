#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq yq-go nix bash common-updater-scripts ripgrep

set -eou pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"
while ! test -f flake.nix; do cd ..; done
FLAKE_DIR="$PWD"

latestVersion=$(
    list-git-tags --url=https://github.com/DonutWare/Fladder |
    rg '^v(.*)' -r '$1' |
    sort --version-sort |
    tail -n1
)

currentVersion=$(nix eval --raw ".#fladder.version")

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "fladder is up-to-date: $currentVersion"
    exit 0
fi

echo "Updating fladder: $currentVersion -> $latestVersion"

# Update version in default.nix
sed -i -E "s@(version\s*=\s*\")[^\"]+@\1${latestVersion}@" "$PACKAGE_DIR"/default.nix

# Update src hash using nix-prefetch
NEW_SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/DonutWare/Fladder/archive/refs/tags/v${latestVersion}.tar.gz" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)
sed -i -E "s@(hash\s*=\s*\")[^\"]+@\1${NEW_SRC_HASH}@" "$PACKAGE_DIR"/default.nix

# Update pubspec.lock.json
curl --fail --silent "https://raw.githubusercontent.com/DonutWare/Fladder/v${latestVersion}/pubspec.lock" | yq eval --output-format=json --prettyPrint >"$PACKAGE_DIR"/pubspec.lock.json

# Update git-hashes.json (only if dart.fetchGitHashesScript is available)
FETCH_SCRIPT=$(nix eval --raw ".#fladder.passthru.dart.fetchGitHashesScript" 2>/dev/null || true)
if [[ -n "$FETCH_SCRIPT" ]]; then
    $FETCH_SCRIPT --input "$PACKAGE_DIR"/pubspec.lock.json --output "$PACKAGE_DIR"/git-hashes.json
else
    echo "Warning: Could not find dart.fetchGitHashesScript, git-hashes.json not updated"
fi

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

echo "fladder updated to $latestVersion"