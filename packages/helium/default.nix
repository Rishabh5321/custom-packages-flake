{ lib
, fetchurl
, appimageTools
}:
let
  pname = "helium";
  version = "0.11.7.1";
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-qzc135IP5F2btxtOMUGMz+0azJhYL9KI0lcPG2KjcxU=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname src version; };
in
appimageTools.wrapType2 {
  inherit pname src version;

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/helium.desktop \
      $out/share/applications/helium.desktop

    # Try to install icon if it exists
    if [ -f ${appimageContents}/helium.png ]; then
      install -Dm644 ${appimageContents}/helium.png \
        $out/share/icons/hicolor/512x512/apps/helium.png
    fi

    substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail 'Exec=helium' 'Exec=${placeholder "out"}/bin/helium'
  '';

  meta = {
    description = "Helium - A simple and modern way to watch anime";
    homepage = "https://github.com/imputnet/helium-linux";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "helium";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
