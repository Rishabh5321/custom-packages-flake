#!/usr/bin/env bash
set -euo pipefail

# OpenCode Update Script
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$PACKAGE_DIR/default.nix"

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' "$PACKAGE_FILE" || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

echo "Fetching latest version from npm registry..."
LATEST_VERSION=$(curl -sL "https://registry.npmjs.org/@opencode/cli/latest" | jq -r '.version')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Could not fetch latest version from npm registry. Trying opencode.ai API..."
    LATEST_VERSION=$(curl -sL "https://opencode.ai/update/api/latest/cli/npm" | jq -r '.version')
fi

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Could not fetch latest version."
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "OpenCode is up-to-date."
    if [ -n "${GITHUB_ENV:-}" ]; then
        echo "UPDATE_DETECTED=false" >> "$GITHUB_ENV"
    fi
    exit 0
fi

echo "Update needed: $CURRENT_VERSION -> $LATEST_VERSION"
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "UPDATE_DETECTED=true" >> "$GITHUB_ENV"
    echo "LATEST_VERSION=$LATEST_VERSION" >> "$GITHUB_ENV"
fi

get_hash() {
    local url="$1"
    local raw_hash
    raw_hash=$(nix-prefetch-url "$url")
    nix hash convert --to sri --hash-algo sha256 "$raw_hash" 2>/dev/null || nix hash to-sri --type sha256 "$raw_hash"
}

echo "Prefetching hashes for OpenCode $LATEST_VERSION..."
HASH_X86_64=$(get_hash "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${LATEST_VERSION}.tgz")
HASH_ARM64=$(get_hash "https://registry.npmjs.org/@opencode/cli-linux-arm64/-/cli-linux-arm64-${LATEST_VERSION}.tgz")

echo "x86_64-linux: $HASH_X86_64"
echo "aarch64-linux: $HASH_ARM64"

cat > "$PACKAGE_FILE" << EOF
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, installShellFiles
}:

let
  pname = "opencode";
  version = "${LATEST_VERSION}";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-\${version}.tgz";
      hash = "${HASH_X86_64}";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-arm64/-/cli-linux-arm64-\${version}.tgz";
      hash = "${HASH_ARM64}";
    };
  };

  srcInfo = sources.\${stdenv.hostPlatform.system}
    or (throw "Unsupported system: \${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    inherit (srcInfo) url hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    installShellFiles
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  sourceRoot = "package";

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/opencode \$out/bin/opencode
    ln -s \$out/bin/opencode \$out/bin/opencode2

    runHook postInstall
  '';

  postFixup = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    autoPatchelf "\$out"
    export HOME=\$(mktemp -d)
    installShellCompletion --cmd opencode \
      --bash <(\$out/bin/opencode --completions bash) \
      --zsh <(\$out/bin/opencode --completions zsh) \
      --fish <(\$out/bin/opencode --completions fish)
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "The open source coding agent";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    maintainers = with maintainers; [ Rishabh5321 ];
    platforms = builtins.attrNames sources;
    mainProgram = "opencode";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
EOF

echo "OpenCode successfully updated to $LATEST_VERSION."
