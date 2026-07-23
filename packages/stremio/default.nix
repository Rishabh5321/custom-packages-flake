{ lib
, rustPlatform
, fetchFromGitHub
, versionCheckHook
, gettext
, glib
, # buildInputs
  gtk4
, glib-networking
, libadwaita
, libepoxy
, libsoup_3
, mpv
, webkitgtk_6_0
, librsvg
, gst_all_1
, # nativeBuildInputs
  pkg-config
, wrapGAppsHook4
, # Wrapper
  nodejs
,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "stremio-linux-shell";
  version = "1.1.4";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Stremio";
    repo = "stremio-linux-shell";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cwETbsY9WEqOi59jObTUKfcoWZxJ0JS4Ql31dCxz2TA=";
  };

  cargoHash = "sha256-n1JBFJxYPhndkPx8izuUNkiefKHXrL19sk+XK7+W0xA=";

  nativeBuildInputs = [
    gettext
    glib
    pkg-config
    wrapGAppsHook4
  ];

  postPatch = ''
    echo 'fn main() {}' > build.rs
    substituteInPlace src/config.rs \
      --replace-warn 'concat!(env!("CARGO_MANIFEST_DIR"), "/po")' "\"$out/share/locale\""
  '';

  buildInputs = [
    gtk4
    libadwaita
    glib-networking
    libepoxy
    libsoup_3
    mpv
    webkitgtk_6_0
    librsvg
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  postInstall = ''
    install -Dm644 data/com.stremio.Stremio.desktop $out/share/applications/com.stremio.Stremio.desktop
    install -Dm644 data/icons/com.stremio.Stremio.svg $out/share/icons/hicolor/scalable/apps/com.stremio.Stremio.svg
    install -Dm644 data/server.js $out/share/stremio/server.js

    # Install schemas
    install -Dm644 data/com.stremio.Stremio.gschema.xml $out/share/glib-2.0/schemas/com.stremio.Stremio.gschema.xml
    glib-compile-schemas $out/share/glib-2.0/schemas

    # Install translations
    for po in po/*.po; do
      lang=$(basename $po .po)
      mkdir -p $out/share/locale/$lang/LC_MESSAGES
      msgfmt -o $out/share/locale/$lang/LC_MESSAGES/stremio.mo $po
    done

    mv $out/bin/stremio-linux-shell $out/bin/stremio
  '';

  # Node.js is required to run `server.js`
  # Add to `gappsWrapperArgs` to avoid two layers of wrapping.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : "${lib.makeBinPath [ nodejs ]}" \
      --prefix SERVER_PATH : "$out/share/stremio/server.js" \
      --set LC_NUMERIC C
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
