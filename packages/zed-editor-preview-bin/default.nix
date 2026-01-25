{ stdenv
, fetchurl
, patchelf
, makeWrapper
, libbsd
, libX11
, libXau
, libxcb
, libXdmcp
, libxkbcommon
, zlib
, alsa-lib
, wayland
, vulkan-loader
, buildFHSEnv
, nix-update-script
, testers
, lib
,
}:
let
  version = "0.221.3-pre";

  # Map from Nix system → { url, sha256, type }
  assets = {
    "x86_64-linux" = {
      url =
        "https://github.com/zed-industries/zed/releases/download/"
        + "v${version}/zed-linux-x86_64.tar.gz";
      sha256 = "sha256-zA+DeTGp4pIeT7A1ByShOLowfGXhdUVbFCRCq2iUg4c=";
      type = "tar.gz";
    };
    "aarch64-linux" = {
      url =
        "https://github.com/zed-industries/zed/releases/download/"
        + "v${version}/zed-linux-aarch64.tar.gz";
      sha256 = "sha256-LByy0t/+EPP1+pThPcwoHPLLUI3WXFaJRXW0j7NOf04=";
      type = "tar.gz";
    };
    "x86_64-darwin" = {
      url =
        "https://github.com/zed-industries/zed/releases/download/"
        + "v${version}/Zed-x86_64.dmg";
      sha256 = "sha256-aj+bWrzy+Act6cyk5cMhA6Yc2tQCTgH9b5ho+N2dX4A=";
      type = "dmg";
    };
    "aarch64-darwin" = {
      url =
        "https://github.com/zed-industries/zed/releases/download/"
        + "v${version}/Zed-aarch64.dmg";
      sha256 = "sha256-BaVAIb7b9ay5xhZzZ7Y3/OB/VDc1imdGJxQB31qhkPM=";
      type = "dmg";
    };
  };

  inherit (stdenv.hostPlatform) system;# or simply `stdenv.system`
  info =
    if lib.hasAttr system assets
    then assets.${system}
    else lib.throwError "zed-editor-bin: unsupported system ${system}";

  nixDeps = lib.optionals stdenv.hostPlatform.isLinux [
    libbsd
    libX11
    libXau
    libxcb
    libXdmcp
    libxkbcommon
    zlib
    alsa-lib
    wayland
    vulkan-loader
  ];

  libPath = lib.makeLibraryPath nixDeps;

  executableName = "zeditor";
  # Based on vscode.fhs
  # Zed allows for users to download and use extensions
  # which often include the usage of pre-built binaries.
  # See #309662
  #
  # buildFHSEnv allows for users to use the existing Zed
  # extension tooling without significant pain.
  fhs =
    { zed-editor
    , additionalPkgs ? pkgs: [ ]
    ,
    }:
    buildFHSEnv {
      # also determines the name of the wrapped command
      name = executableName;

      # additional libraries which are commonly needed for extensions
      targetPkgs = pkgs:
        (with pkgs; [
          # ld-linux-x86-64-linux.so.2 and others
          glibc
        ])
        ++ additionalPkgs pkgs;

      # symlink shared assets, including icons and desktop entries
      extraInstallCommands = ''
        ln -s "${zed-editor}/share" "$out/"
      '';

      runScript = "${zed-editor}/bin/${executableName}";

      passthru = {
        inherit executableName;
        inherit (zed-editor) pname version;
      };

      meta =
        zed-editor.meta
        // {
          description = ''
            Wrapped variant of ${zed-editor.pname} which launches in a FHS compatible environment.
            Should allow for easy usage of extensions without nix-specific modifications.
          '';
        };
    };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zed-editor-bin";
  inherit version;

  # only on Linux do we need patchelf & makeWrapper
  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [ patchelf makeWrapper ];

  # on Linux pull in the real libraries
  buildInputs = nixDeps;

  src = fetchurl {
    inherit (info) url;
    inherit (info) sha256;
  };

  phases = [ "unpackPhase" "installPhase" ];

  unpackPhase = ''
    if [ "${info.type}" = "tar.gz" ]; then
      tar xzf "$src"
    else
      mount=./mnt
      mkdir -p "$mount"
      /usr/bin/hdiutil attach "$src" -nobrowse -mountpoint "$mount"
      cp -R "$mount"/*.app .
      /usr/bin/hdiutil detach "$mount"
    fi
  '';

  installPhase = ''
    appdir="$(find . -maxdepth 1 -type d -name '*.app' -print -quit)"

    if [ "${info.type}" = "tar.gz" ]; then
    	mkdir -p $out/{bin,libexec,share}

    	# copy the executables
    	cp "$appdir/bin/zed"       $out/bin/
    	cp "$appdir/libexec/zed-editor" $out/libexec/

    	# copy the share tree (icons, desktop files, etc)
    	cp -R "$appdir/share"/* $out/share/

    	patchelf \
    	--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    	--set-rpath "${lib.makeLibraryPath ([stdenv.cc.cc] ++ nixDeps)}" \
    	"$out/bin/zed"

    	patchelf \
    	--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    	--set-rpath "${lib.makeLibraryPath ([stdenv.cc.cc] ++ nixDeps)}" \
    	"$out/libexec/zed-editor"

    	# wrap them so they pick up our Nix store libraries
    	wrapProgram $out/bin/zed \
    	--prefix LD_LIBRARY_PATH ":" ${libPath}

    	wrapProgram $out/libexec/zed-editor \
    	--prefix LD_LIBRARY_PATH ":" ${libPath}

    	# provide a zeditor‐alias
    	ln -s zed $out/bin/zeditor

    else
    	# macOS: ship the .app
    	mkdir -p $out/Applications $out/bin
    	mv "$appdir" $out/Applications/
    	ln -s "$out/Applications/$(basename "$appdir")/Contents/MacOS/Zed" \
    	$out/bin/zeditor
    fi
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "^v(?!.*(?:-pre|0\.999999\.0|0\.9999-temporary)$)(.+)$"
      ];
    };
    fhs = fhs { zed-editor = finalAttrs.finalPackage; };
    fhsWithPackages = f:
      fhs {
        zed-editor = finalAttrs.finalPackage;
        additionalPkgs = f;
      };
    tests = {
      remoteServerVersion = testers.testVersion {
        package = finalAttrs.finalPackage.remote_server;
        command = "zed-remote-server-stable-${finalAttrs.version} version";
      };
    };
  };

  meta = with lib; {
    description = "High-performance, multiplayer code editor from the creators of Atom and Tree-sitter";
    homepage = "https://zed.dev";
    changelog = "https://github.com/zed-industries/zed/releases/tag/v${finalAttrs.version}";
    mainProgram = executableName;
    license = licenses.gpl3Only;
    platforms = attrNames assets;
  };
})
