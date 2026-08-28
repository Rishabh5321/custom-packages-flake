{ lib
, fetchurl
, appimageTools
}:

let
  pname = "zcode";
  version = "3.10.1";

  src = fetchurl {
    name = "${pname}-${version}.AppImage";
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.AppImage";
    hash = "sha256-9T/d0uf3roTimyZgy0oMaHyUmdZbmKdOIifAAWdOI1o=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/zcode.desktop $out/share/applications/zcode.desktop
    substituteInPlace $out/share/applications/zcode.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'

    if [ -d ${appimageContents}/usr/share/icons ]; then
      mkdir -p $out/share
      cp -r ${appimageContents}/usr/share/icons $out/share/
    elif [ -f ${appimageContents}/zcode.png ]; then
      install -m 444 -D ${appimageContents}/zcode.png \
        $out/share/icons/hicolor/512x512/apps/zcode.png
    fi
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Official Harness for GLM-5.3 - AI coding agent desktop application";
    homepage = "https://zcode.z.ai/en";
    license = licenses.unfree; # Proprietary AI client
    maintainers = with maintainers; [ Rishabh5321 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "zcode";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
