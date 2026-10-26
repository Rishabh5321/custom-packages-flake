#!/usr/bin/env bash
set -eou pipefail

# Cage XtMapper Update Script
# Upstream ships date based tags (vYYYYMMDD) plus a rolling "latest" tag.
# Upstream vendors cage and wlroots as git submodules under forks/, so the
# tag and both submodule versions have to be kept in sync.

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$PACKAGE_DIR/default.nix"

read_field() {
    grep -oP "$1\s*=\s*\"\K[^\"]+" "$PACKAGE_FILE" | head -1
}

CURRENT_TAG=$(read_field 'tag')
CURRENT_CAGE_VERSION=$(read_field 'cageVersion')
echo "Current tag: $CURRENT_TAG (cage $CURRENT_CAGE_VERSION)"

echo "Fetching tags from GitHub API..."
TAGS=$(gh api repos/Xtr126/cage-xtmapper/tags --paginate)

LATEST_TAG=$(echo "$TAGS" | jq -r '[.[] | select(.name | test("^v[0-9]{8}$"))][0].name')
LATEST_SHA=$(echo "$TAGS" | jq -r '[.[] | select(.name | test("^v[0-9]{8}$"))][0].commit.sha')

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" == "null" ]; then
    echo "Could not extract a valid release tag."
    exit 1
fi

echo "Latest tag: $LATEST_TAG"

if [ "$CURRENT_TAG" = "$LATEST_TAG" ]; then
    echo "Cage XtMapper is up-to-date."
    if [ -n "${GITHUB_ENV:-}" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

# Upstream uses submodules in forks/cage and forks/wlroots-xtmapper (newer releases),
# or vendored tarballs in root (older releases).
TREE=$(gh api "repos/Xtr126/cage-xtmapper/git/trees/$LATEST_SHA?recursive=1")

CAGE_SUBMODULE_SHA=$(echo "$TREE" | jq -r '.tree[] | select(.path == "forks/cage").sha // empty')
WLROOTS_SUBMODULE_SHA=$(echo "$TREE" | jq -r '.tree[] | select(.path == "forks/wlroots-xtmapper").sha // empty')

LATEST_CAGE_VERSION=""
LATEST_WLROOTS_VERSION=""

if [ -n "$CAGE_SUBMODULE_SHA" ]; then
    LATEST_CAGE_VERSION=$(gh api "repos/Xtr126/cage/contents/meson.build?ref=$CAGE_SUBMODULE_SHA" | jq -r .content | base64 -d | grep -oP "version:\s*'\K[^']+" | head -1)
fi

if [ -n "$WLROOTS_SUBMODULE_SHA" ]; then
    LATEST_WLROOTS_VERSION=$(gh api "repos/Xtr126/wlroots-xtmapper/contents/meson.build?ref=$WLROOTS_SUBMODULE_SHA" | jq -r .content | base64 -d | grep -oP "version:\s*'\K[^']+" | head -1)
fi

# Fallback for older vendored tarball layout
vendored_version() {
    echo "$TREE" | jq -r --arg p "$1" '
      [ .tree[].path
        | select(test("^" + $p + "-[0-9][^/]*\\.tar\\.gz$"))
        | sub("^" + $p + "-"; "") | sub("\\.tar\\.gz$"; "")
      ][0] // ""'
}

if [ -z "$LATEST_CAGE_VERSION" ]; then
    LATEST_CAGE_VERSION=$(vendored_version cage)
fi

if [ -z "$LATEST_WLROOTS_VERSION" ]; then
    LATEST_WLROOTS_VERSION=$(vendored_version wlroots)
fi

if [ -z "$LATEST_CAGE_VERSION" ] || [ -z "$LATEST_WLROOTS_VERSION" ]; then
    echo "Could not determine the vendored cage/wlroots versions."
    exit 1
fi

echo "Vendored sources: cage $LATEST_CAGE_VERSION, wlroots $LATEST_WLROOTS_VERSION"
echo "Update needed: $CURRENT_TAG -> $LATEST_TAG"

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$LATEST_CAGE_VERSION" >> "$GITHUB_ENV"
fi

echo "Prefetching..."
PREFETCH_JSON=$(nix-prefetch-github --fetch-submodules Xtr126 cage-xtmapper --rev "$LATEST_TAG")
NEW_HASH=$(echo "$PREFETCH_JSON" | jq -r .hash)

if [ -z "$NEW_HASH" ] || [ "$NEW_HASH" == "null" ]; then
    echo "Failed to calculate hash."
    exit 1
fi

echo "New Hash: $NEW_HASH"

sed -i -E "s@(tag\s*=\s*\")[^\"]+@\1${LATEST_TAG}@" "$PACKAGE_FILE"
sed -i -E "s@(cageVersion\s*=\s*\")[^\"]+@\1${LATEST_CAGE_VERSION}@" "$PACKAGE_FILE"
sed -i -E "s@(wlrootsVersion\s*=\s*\")[^\"]+@\1${LATEST_WLROOTS_VERSION}@" "$PACKAGE_FILE"
sed -i -E "s|(hash\s*=\s*\")[^\"]+(\";)|\1${NEW_HASH}\2|" "$PACKAGE_FILE"

echo "Cage XtMapper updated."