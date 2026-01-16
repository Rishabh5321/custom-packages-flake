#!/usr/bin/env bash
set -e

# Update script for Thorium (AVX, AVX2, SSE3, SSE4)

REPO="Alex313031/thorium"
FILE_PATH=$(dirname "$(readlink -f "$0")")/default.nix

echo "Fetching latest release for $REPO..."
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r .tag_name)
LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^M//')

echo "Latest TAG: $LATEST_TAG"
echo "Latest VERSION: $LATEST_VERSION"

# Update version in file (occurs multiple times, but all should be same)
sed -i -E "s/version = \"[0-9.]+\"/version = \"$LATEST_VERSION\"/" "$FILE_PATH"

VARIANTS=("AVX" "AVX2" "SSE3" "SSE4")

for VARIANT in "${VARIANTS[@]}"; do
    echo "Processing $VARIANT..."
    # URL Format: https://github.com/Alex313031/thorium/releases/download/M138.0.7204.300/Thorium_Browser_138.0.7204.300_AVX.AppImage
    URL="https://github.com/$REPO/releases/download/${LATEST_TAG}/Thorium_Browser_${LATEST_VERSION}_${VARIANT}.AppImage"
    
    echo "Prefetching $URL..."
    # nix-prefetch-url might fail if the asset doesn't exist (e.g. slight naming chance).
    SHA256=$(nix-prefetch-url "$URL")
    SRI_HASH=$(nix hash to-sri --type sha256 "$SHA256")
    
    echo "$VARIANT Hash: $SRI_HASH"
    
    # We need to target the specific hash for the specific variant block.
    # The file structure is:
    # thorium-avx = ...
    #   hash = "...";
    # thorium-avx2 = ...
    # We can rely on the url line to identify the block, then change the hash in the following lines.
    # But simpler: search for the specific AppImage filename (which contains the variant) in the URL line,
    # then replace the hash on the next line.
    
    # Using sed with range/context address
    # Find line with "_${VARIANT}.AppImage", then on the NEXT line matching "hash =", replace it.
    
    # Be careful with sed escaping.
    sed -i -E "/_${VARIANT}.AppImage/!b;n;c\    hash = \"$SRI_HASH\";" "$FILE_PATH"
done

echo "Updated Thorium variants in $FILE_PATH"
