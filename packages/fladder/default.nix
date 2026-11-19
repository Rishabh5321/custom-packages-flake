{ lib
, fetchurl
, appimageTools
, libepoxy
, lz4
, mpv-unwrapped
,
}:
let
  pname = "fladder";
  version = "0.12.0";
  src = fetchurl {
    url = "https://github.com/DonutWare/Fladder/releases/download/v${version}/Fladder-Linux-${version}.AppImage";
    hash = "sha256-6nCZtFdrn/6oofbpSjVu004o6f5cpmN+M7QqUAokG5s=";
  };

  appimageContents = appimageTools.extract { inherit pname src version; };
in
appimageTools.wrapType2 {
  inherit pname src version;

  # Libraries that the AppImage expects from the host system: libepoxy for the
  # Flutter engine, liblz4 for libmdk and libmpv.so.2 for media_kit.
  extraPkgs = _: [
    libepoxy
    lz4
    mpv-unwrapped
  ];

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/fladder_icon_desktop.png \
      $out/share/icons/hicolor/1024x1024/apps/fladder_icon_desktop.png

    install -Dm644 ${appimageContents}/nl.jknaapen.fladder.desktop \
      $out/share/applications/fladder.desktop
    substituteInPlace $out/share/applications/fladder.desktop \
      --replace-fail 'Exec=fladder' 'Exec=${placeholder "out"}/bin/fladder' \
      --replace-fail 'Categories=Utility;' 'Categories=AudioVideo;Video;Player;' \
      --replace-fail 'Comment=' 'Comment=Simple Jellyfin Frontend built on top of Flutter'
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Simple Jellyfin Frontend built on top of Flutter";
    homepage = "https://github.com/DonutWare/Fladder";
    downloadPage = "https://github.com/DonutWare/Fladder/releases";
    changelog = "https://github.com/DonutWare/Fladder/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "fladder";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
