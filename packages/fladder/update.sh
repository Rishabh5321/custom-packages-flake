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

# Update git-hashes.json
echo "Updating git-hashes.json"
echo "{}" > "$PACKAGE_DIR"/git-hashes.json
jq -r '.packages | to_entries[] | select(.value.source == "git") | "\(.key) \(.value.description.url) \(.value.description["resolved-ref"])"' "$PACKAGE_DIR"/pubspec.lock.json | while read -r pkg url ref; do
    if [[ "$url" == "https://github.com/"* ]]; then
        repo_path="${url#https://github.com/}"
        repo_path="${repo_path%.git}"
        archive_url="https://github.com/${repo_path}/archive/${ref}.tar.gz"
        hash=$(nix-prefetch-url --unpack "$archive_url" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)
        jq ".[\"$pkg\"] = \"$hash\"" "$PACKAGE_DIR"/git-hashes.json > "$PACKAGE_DIR"/git-hashes.tmp.json
        mv "$PACKAGE_DIR"/git-hashes.tmp.json "$PACKAGE_DIR"/git-hashes.json
    else
        echo "Warning: Unsupported git URL $url for package $pkg"
    fi
done

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latestVersion" >> "$GITHUB_ENV"
fi

echo "fladder updated to $latestVersion"