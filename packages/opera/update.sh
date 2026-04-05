#!/usr/bin/env bash
set -euo pipefail

# Opera Update Script

pname="opera"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_file="$script_dir/default.nix"

# Export default state for GitHub Actions
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
fi

echo "Checking latest version for Opera..."

# Get the latest versions from the Opera download server
# We check the most recent versions and look for one that has a Linux binary
all_versions=$(curl -sL https://get.geo.opera.com/pub/opera/desktop/ | grep -oP 'href="\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -rV)
# We limit to the top 10 most recent versions to check for Linux binaries
recent_versions=$(echo "$all_versions" | head -n 10)

latest_rev=""
for v in $recent_versions; do
    check_url="https://get.geo.opera.com/pub/opera/desktop/${v}/linux/opera-stable_${v}_amd64.deb"
    if curl -sLI --head "$check_url" | grep "200 OK" > /dev/null; then
        latest_rev=$v
        break
    fi
done

if [ -z "$latest_rev" ]; then
    echo "❌ Failed to fetch latest version with Linux binary"
    exit 1
fi

echo "Latest version: $latest_rev"

current_rev=$(grep -oP 'version\s*=\s*"\K[^"]+' "$package_file" | head -n1)
echo "Current version in default.nix: $current_rev"

if [[ "$latest_rev" == "$current_rev" ]]; then
    echo "✅ Package is already at the latest version ($current_rev). Nothing to do."
    exit 0
fi

echo "⚡ Update needed: $current_rev -> $latest_rev"

if [ -n "${GITHUB_ENV:-}" ]; then
    sed -i "/UPDATE_DETECTED=false/d" "$GITHUB_ENV"
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$latest_rev" >> "$GITHUB_ENV"
fi

# Backup + trap
orig_file=$(mktemp)
cp "$package_file" "$orig_file"
trap 'echo "❌ Error occurred, restoring default.nix"; cp "$orig_file" "$package_file"' ERR

# Update version
sed -i 's|^\(\s*version\s*=\s*\)".*"|\1"'"$latest_rev"'"|' "$package_file"

# Calculate Hash
DOWNLOAD_URL="https://get.geo.opera.com/pub/opera/desktop/${latest_rev}/linux/opera-stable_${latest_rev}_amd64.deb"
echo "Download URL: $DOWNLOAD_URL"

echo "Calculating hash..."
NEW_HASH=$(nix-prefetch-url --type sha256 "$DOWNLOAD_URL")
SRI_HASH=$(nix hash to-sri --type sha256 "$NEW_HASH")

if [ -z "$SRI_HASH" ]; then
    echo "❌ Failed to calculate SRI hash"
    exit 1
fi

echo "New SRI Hash: $SRI_HASH"
sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${SRI_HASH}\2|" "$package_file"

# Cleanup
trap - ERR
rm "$orig_file"

echo "✅ Update completed successfully!"
echo "Package is now at version $latest_rev."
