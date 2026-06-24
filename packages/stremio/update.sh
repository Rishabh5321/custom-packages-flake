#!/usr/bin/env bash
set -e

# Stremio Update Script
# Updates to the latest tag, gets the source hash, and updates cargoHash using nix build

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

# 2. Prefetch source code hash
echo "Prefetching source code..."
SRC_HASH=$(nix-prefetch-github Stremio stremio-linux-shell --rev "${LATEST_TAG}" | jq -r .hash)
echo "  Source Hash: $SRC_HASH"

FILE="packages/stremio/default.nix"

# 3. Update version and source hash in default.nix
sed -i -E "s@(version\s*=\s*\")[^\"]+(\";)@\1${VERSION}\2@" "$FILE"
sed -i -E "s@(hash\s*=\s*\")[^\"]+(\";)@\1${SRC_HASH}\2@" "$FILE"

# 4. Set cargoHash to fake hash to force nix to rebuild cargo deps and show the correct hash
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
sed -i -E "s@(cargoHash\s*=\s*\")[^\"]+(\";)@\1${FAKE_HASH}\2@" "$FILE"

# 5. Run nix build and capture the hash mismatch error
echo "Building package to calculate cargoHash..."
BUILD_OUTPUT=$(nix build .#stremio --no-link 2>&1 || true)

CARGO_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got:\s+\Ksha256-\S+' || echo "$BUILD_OUTPUT" | grep -o 'sha256-[a-zA-Z0-9/+=]*' | tail -n 1)

if [ -z "$CARGO_HASH" ] || [ "$CARGO_HASH" == "$FAKE_HASH" ]; then
    echo "Failed to calculate cargoHash. Build output:"
    echo "$BUILD_OUTPUT"
    exit 1
fi

echo "  Cargo Hash:  $CARGO_HASH"

# 6. Update cargoHash in default.nix
sed -i -E "s@(cargoHash\s*=\s*\")[^\"]+(\";)@\1${CARGO_HASH}\2@" "$FILE"

echo "Update complete!"
