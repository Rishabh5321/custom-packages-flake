{ appimageTools, fetchurl, lib }:
let
  pname = "altersend";
  version = "1.5.0";
  src = fetchurl {
    name = "${pname}-${version}.AppImage";
    url = "https://github.com/denislupookov/altersend/releases/download/v${version}/AlterSend-x86_64.AppImage";
    hash = "sha256-XQWo39Q8RCqWCvVvpDmYzEYQgxwhpeJH86PReqmqXOU=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname} || true
    
    install -m 444 -D ${appimageContents}/@altersenddesktop.desktop $out/share/applications/altersend.desktop
    substituteInPlace $out/share/applications/altersend.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}' \
      --replace-fail 'Icon=@altersenddesktop' 'Icon=${pname}'

    install -m 444 -D ${appimageContents}/@altersenddesktop.png \
      $out/share/icons/hicolor/1024x1024/apps/altersend.png
  '';

  meta = {
    description = "A free, open-source, cross-platform application designed for private, peer-to-peer file transfers";
    homepage = "https://github.com/denislupookov/altersend";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.asl20;
    mainProgram = "altersend";
  };
}
