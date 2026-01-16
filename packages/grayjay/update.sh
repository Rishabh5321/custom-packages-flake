#!/usr/bin/env bash
set -e

# Grayjay Update Script
# 
# Since Grayjay uses a static URL for the latest zip, we must:
# 1. Download the zip
# 2. Calculate its hash
# 3. Check the internal directory structure for versioning (e.g. v13)
# 4. Update default.nix if either changes

url="https://updater.grayjay.app/Apps/Grayjay.Desktop/Grayjay.Desktop-linux-x64.zip"
nix_file="packages/grayjay/default.nix"

echo "Fetching latest Grayjay zip..."
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

zip_file="$temp_dir/grayjay.zip"
curl -L -s -o "$zip_file" "$url"

# Calculate hash
echo "Calculating hash..."
current_hash=$(grep -oP 'sha256\s*=\s*"\K[^"]+' "$nix_file" || echo "")
new_hash=$(nix hash file "$zip_file" --type sha256) # SRI or base32 depending on version, usually SRI now but we might want base32 to match

# nix hash file often returns SRI (sha256-...). 
# The file currently uses base32 (081...). Let's convert to base32 for consistency if the current one is base32.
if [[ "$current_hash" != sha256-* ]] && [[ "$new_hash" == sha256-* ]]; then
    # Convert SRI to base32
    new_hash=$(nix hash to-base32 "$new_hash")
fi

echo "Current hash: $current_hash"
echo "New hash:     $new_hash"

# Check internal directory version
echo "Checking internal version..."
unzip -q -l "$zip_file" > "$temp_dir/list.txt"
# Look for the main directory pattern: Grayjay.Desktop-linux-x64-v[NUMBER]
# We grep for lines ending in /Grayjay to find the path
internal_dir=$(grep -oP 'Grayjay\.Desktop-linux-x64-v\d+(?=/Grayjay)' "$temp_dir/list.txt" | head -n 1)

if [ -z "$internal_dir" ]; then
    echo "Error: Could not determine internal versioned directory from zip."
    exit 1
fi

echo "Internal dir: $internal_dir"

# Get current internal dir from nix file
current_dir=$(grep -oP 'Grayjay\.Desktop-linux-x64-v\d+(?=/Grayjay")' "$nix_file" | head -n 1)
echo "Current dir:  $current_dir"


update_needed=false

if [ "$current_hash" != "$new_hash" ]; then
    echo "Hash mismatch. Update needed."
    update_needed=true
fi

if [ "$current_dir" != "$internal_dir" ]; then
    echo "Directory version mismatch. Update needed."
    update_needed=true
fi

if [ "$update_needed" = true ]; then
    echo "Updating $nix_file..."
    
    # Update hash
    sed -i "s|$current_hash|$new_hash|" "$nix_file"
    
    # Update directory version
    # Use | as delimiter to avoid path issues, though this is just a directory name
    sed -i "s|$current_dir|$internal_dir|g" "$nix_file"
    
    echo "Update complete."
else
    echo "No update needed."
fi
