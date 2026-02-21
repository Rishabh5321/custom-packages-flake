#!/usr/bin/env bash
set -euo pipefail

# Antigravity Update Script
# Compliant with .github/workflows/update-packages.yml

pname="antigravity"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_file="$script_dir/default.nix"

# Export default state for GitHub Actions
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
fi

# Check latest version
echo "Checking latest version"
latest_rev=$(
  curl -sL --compressed https://antigravity.google/ \
  | grep -Eo 'main-[^"]+\.js' | head -n1 \
  | xargs -I{} curl -sL --compressed https://antigravity.google/{} \
  | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' | head -n1
)
echo "Latest commit: $latest_rev"

current_rev=$(grep -oP 'version\s*=\s*"\K[^"]+' "$package_file" | head -n1)
echo "Current rev in default.nix: $current_rev"

if [[ "$latest_rev" == "$current_rev" ]]; then
    echo "✅ Package is already at the latest commit ($current_rev). Nothing to do."
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

# Update version and temporary hash to trigger build failure and get correct hash
dummy_src="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
sed -i 's|^\(\s*version\s*=\s*\)".*"|\1"'"$latest_rev"'"|' "$package_file"
sed -i 's|^\(\s*hash\s*=\s*\)".*"|\1"'"$dummy_src"'"|' "$package_file"

echo "Building to get src hash..."
# Use absolute path to flake root for nix build
flake_root="$(cd "$script_dir/../.." && pwd)"
output=$(nix build "$flake_root"#$pname 2>&1 || true)

src_hash=$(echo "$output" | grep 'got:' | head -n1 | grep -oP 'sha256-[a-zA-Z0-9+/=]+')
if [ -z "$src_hash" ]; then
    echo "❌ Failed to extract src hash from build output"
    echo "$output" | tail -n20
    exit 1
fi

echo "New src hash: $src_hash"
sed -i "s|$dummy_src|$src_hash|" "$package_file"

# Cleanup
trap - ERR
rm "$orig_file"

echo "✅ Update completed successfully!"
echo "Package is now at version $latest_rev."

