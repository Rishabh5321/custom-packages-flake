{ lib
, fetchurl
, appimageTools
}:

let
  pname = "bitchord";
  version = "1.8";

  src = fetchurl {
    name = "BitChord-${version}-linux-x86_64.AppImage";
    url = "https://github.com/kushagrasinghx/BitChord/releases/download/v${version}/BitChord-${version}-linux-x86_64.AppImage";
    hash = "sha256-WSZiB8ar3ba0u76FcM1pwTd/So9eWMJLloJPZY9GUbg=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/bitchord.desktop $out/share/applications/bitchord.desktop
    substituteInPlace $out/share/applications/bitchord.desktop \
      --replace-fail 'Exec=BitChord' 'Exec=${pname}'

    if [ -f ${appimageContents}/bitchord.png ]; then
      install -m 444 -D ${appimageContents}/bitchord.png \
        $out/share/icons/hicolor/512x512/apps/bitchord.png
    elif [ -f ${appimageContents}/.DirIcon ]; then
      install -m 444 -D ${appimageContents}/.DirIcon \
        $out/share/icons/hicolor/512x512/apps/bitchord.png
    fi
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Aesthetic YouTube Music client (desktop beta)";
    homepage = "https://github.com/kushagrasinghx/BitChord";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ Rishabh5321 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "bitchord";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
