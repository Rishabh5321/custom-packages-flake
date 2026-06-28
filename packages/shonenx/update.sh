#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

set -euo pipefail

OWNER="roshancodespace"
REPO="ShonenX"
NIX_FILE="packages/shonenx/default.nix"

# Get latest release tag
LATEST_TAG=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | jq -r .tag_name)
VERSION="${LATEST_TAG#v}"

# Get current version from nix file
CURRENT_VERSION=$(grep 'version =' "$NIX_FILE" | cut -d '"' -f 2)

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
    echo "ShonenX is already up to date (version $VERSION)"
    exit 0
fi

echo "Updating ShonenX from $CURRENT_VERSION to $VERSION..."

# Calculate new hash
URL="https://github.com/$OWNER/$REPO/releases/download/$LATEST_TAG/ShonenX-Linux.zip"
NEW_HASH=$(nix-prefetch-url "$URL")

# Update file
sed -i "s/version = \".*\"/version = \"$VERSION\"/" "$NIX_FILE"
sed -i "s/sha256 = \".*\"/sha256 = \"$NEW_HASH\"/" "$NIX_FILE"

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$VERSION" >> "$GITHUB_ENV"
fi

echo "Updated ShonenX to version $VERSION"

