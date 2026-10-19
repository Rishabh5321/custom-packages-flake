{ lib
, appimageTools
, fetchurl
}:

let
  pname = "teledrive";
  version = "1.5.0";

  src = fetchurl {
    url = "https://github.com/Mahmud0808/TeleDrive/releases/download/v${version}/TeleDrive-${version}-x86_64.AppImage";
    hash = "sha256-AjqCuJHxDQMLCQX5BLkI+EuoGRpBc0tDWqVGOtiuLFA=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/*.desktop $out/share/applications/
    substituteInPlace $out/share/applications/*.desktop \
      --replace-fail 'Exec=TeleDrive' 'Exec=${pname}'

    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp ${appimageContents}/teledrive.png $out/share/icons/hicolor/512x512/apps/${pname}.png
  '';

  meta = with lib; {
    description = "Turn a private Telegram channel into your personal cloud drive";
    homepage = "https://github.com/Mahmud0808/TeleDrive";
    downloadPage = "https://github.com/Mahmud0808/TeleDrive/releases";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "teledrive";
  };
}
