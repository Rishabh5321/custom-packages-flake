{
  lib,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,

  # buildInputs
  gtk4,
  glib-networking,
  libadwaita,
  libepoxy,
  libsoup_3,
  mpv,
  webkitgtk_6_0,

  # nativeBuildInputs
  pkg-config,
  wrapGAppsHook4,

  # Wrapper
  nodejs,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "stremio-linux-shell";
  version = "1.0.0-beta.14";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Stremio";
    repo = "stremio-linux-shell";
    tag = "v${finalAttrs.version}";
    hash = "sha256-g7QZ+kYhT7NJ1HKSnV+VBDI/CGeLfJtXn0v9xWCCP/4=";
  };

  cargoHash = "sha256-euD3ogHwmOXu9AwvZDm23bCgmITwS4SntmfNUSL3WbU=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    glib-networking
    libepoxy
    libsoup_3
    mpv
    webkitgtk_6_0
  ];

  postInstall = ''
    install -Dm644 data/com.stremio.Stremio.desktop $out/share/applications/com.stremio.Stremio.desktop
    install -Dm644 data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/com.stremio.Stremio.svg
    install -Dm644 data/server.js $out/share/stremio/server.js

    mv $out/bin/stremio-linux-shell $out/bin/stremio
  '';

  # Node.js is required to run `server.js`
  # Add to `gappsWrapperArgs` to avoid two layers of wrapping.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [ nodejs ]}" \
      --prefix SERVER_PATH : "$out/share/stremio/server.js"
    )
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  meta = {
    description = "Client for Stremio on Linux";
    homepage = "https://www.stremio.com/";
    downloadPage = "https://github.com/Stremio/stremio-linux-shell";
    changelog = "https://github.com/Stremio/stremio-linux-shell/releases/tag/${finalAttrs.src.tag}";
    license =
      with lib.licenses;
      AND [
        gpl3Only
        unfree # server.js
      ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      obfuscatedCode # server.js
    ];
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
    mainProgram = "stremio";
  };
})
