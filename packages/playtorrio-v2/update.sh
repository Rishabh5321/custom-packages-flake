#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq yq-go nix bash common-updater-scripts ripgrep

set -eou pipefail

PACKAGE_DIR="$(realpath "$(dirname "$0")")"
cd "$PACKAGE_DIR"
while ! test -f flake.nix; do cd ..; done
FLAKE_DIR="$PWD"

latestVersion=$(
    curl -s https://api.github.com/repos/ayman708-UX/PlayTorrioV2/releases/latest | jq -r '.tag_name' | sed 's/^v//'
)

echo "Updating playtorrio-v2 to: $latestVersion"

NEW_SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/ayman708-UX/PlayTorrioV2/archive/refs/tags/v${latestVersion}.tar.gz" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri || true)
echo "SRC HASH: $NEW_SRC_HASH"

curl --fail --silent "https://raw.githubusercontent.com/ayman708-UX/PlayTorrioV2/v${latestVersion}/pubspec.lock" | yq eval --output-format=json --prettyPrint >"$PACKAGE_DIR"/pubspec.lock.json
echo "Generated pubspec.lock.json"

# Wait, we need to generate git-hashes.json
# We don't have playtorrio-v2 in flake passthru yet.
# Let's see if fladder's works.
FETCH_SCRIPT=$(nix eval --raw ".#fladder.passthru.dart.fetchGitHashesScript" 2>/dev/null || true)
if [[ -n "$FETCH_SCRIPT" ]]; then
    $FETCH_SCRIPT --input "$PACKAGE_DIR"/pubspec.lock.json --output "$PACKAGE_DIR"/git-hashes.json
    echo "Generated git-hashes.json"
fi

echo "Done"
