# https://github.com/NixOS/nixpkgs/pull/468728
{ lib
, symlinkJoin
, rustPlatform
, atk
, cef-binary
, gtk3
, libayatana-appindicator
, mpv
, openssl
, wrapGAppsHook4
, makeBinaryWrapper
, pkg-config
, libGL
, nodejs
, ffmpeg
, fetchFromGitHub
, ...
}:
let
  # Follow upstream
  # https://github.com/Stremio/stremio-linux-shell/blob/v1.0.0-beta.12/flatpak/com.stremio.Stremio.Devel.json#L150
  cefPinned = cef-binary.override {
    version = "138.0.21";
    gitRevision = "54811fe";
    chromiumVersion = "138.0.7204.101";

    srcHashes = {
      aarch64-linux = ""; # TODO: Add when available
      x86_64-linux = "sha256-Kob/5lPdZc9JIPxzqiJXNSMaxLuAvNQKdd/AZDiXvNI=";
    };
  };

  # Stremio expects CEF files in a specific layout
  cefPath = symlinkJoin {
    name = "stremio-cef-target";
    paths = [
      "${cefPinned}/Resources"
      "${cefPinned}/Release"
    ];
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "stremio-linux-shell";
  src = fetchFromGitHub {
    owner = "Stremio";
    repo = "stremio-linux-shell";
    rev = "57bbfdb6d8773bf4976871b2016ab1ce33fdd9f2";
    sha256 = "sha256-1f9IBNo5gxpSqTSIf8QuQOlf+sfRhohOmQTLRbX/OU8=";
  };
  version = "1.0.0-beta.13";

  cargoLock = {
    lockFile = "${finalAttrs.src}/Cargo.lock";
    outputHashes = {
      # some hashes are missing from the cargo lockfile? Not sure why
      "cef-138.2.2+138.0.21" = "sha256-HfhiNwhCtKcuI27fGTCjk1HA1Icau6SUjXjHqAOllAk=";
      "dpi-0.1.1" = "sha256-5nc8cGFl4jUsJXfEtfOxFBQFRoBrM6/5xfA2c1qhmoQ=";
      "glutin-0.32.3" = "sha256-5IX+03mQmWxlCdVC0g1q2J+ulW+nPTAhYAd25wyaHx8=";
      "libmpv2-4.1.0" = "sha256-zXMFuajnkY8RnVGlvXlZfoMpfifzqzJnt28a+yPZmcQ=";
    };
  };

  postPatch = ''
    substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
  '';

  # Don't download CEF during build
  buildFeatures = [ "offline-build" ];

  buildInputs = [
    atk
    cefPath
    gtk3
    libayatana-appindicator
    mpv
    openssl
  ];

  nativeBuildInputs = [
    wrapGAppsHook4
    makeBinaryWrapper
    pkg-config
  ];

  env.CEF_PATH = "${cefPath}";

  postInstall = ''
    mkdir -p $out/share/applications
    cp data/com.stremio.Stremio.desktop $out/share/applications/com.stremio.Stremio.desktop

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/com.stremio.Stremio.svg

    cp data/server.js $out/bin/server.js
    mv $out/bin/stremio-linux-shell $out/bin/stremio
  '';

  # Node.js is required to run `server.js`
  # Add to `gappsWrapperArgs` to avoid two layers of wrapping.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL]}" \
      --prefix PATH : "${lib.makeBinPath [nodejs ffmpeg]}" \
      --set LC_NUMERIC C \
      --add-flags "--enable-features=UseOzonePlatform --ozone-platform-hint=auto"
    )
  '';

  meta = {
    description = "Modern media center that gives you the freedom to watch everything you want";
    homepage = "https://www.stremio.com/";
    license = with lib.licenses; [
      gpl3Only
      # server.js is unfree
      unfree
    ];
    maintainers = with lib.maintainers; [ thunze ];
    platforms = lib.platforms.linux;
    mainProgram = "stremio";
  };
})
