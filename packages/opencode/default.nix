{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, installShellFiles
}:

let
  pname = "opencode";
  version = "2.2.1";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
      hash = "sha256-Qs8d3ffRq63O6JWsnGZInsmUuMZQsfSuydOz59B9ml4=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-arm64/-/cli-linux-arm64-${version}.tgz";
      hash = "sha256-LO4SZ3wxDdFz+Z6WlSYSz2zSAxl303YuOuqmdn/Xsgs=";
    };
  };

  srcInfo = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
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

    install -Dm755 bin/opencode $out/bin/opencode
    ln -s $out/bin/opencode $out/bin/opencode2

    runHook postInstall
  '';

  postFixup = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    autoPatchelf "$out"
    export HOME=$(mktemp -d)
    installShellCompletion --cmd opencode       --bash <($out/bin/opencode --completions bash)       --zsh <($out/bin/opencode --completions zsh)       --fish <($out/bin/opencode --completions fish)
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
