{ appimageTools, fetchurl, lib }:
let
  pname = "altersend";
  version = "1.7.0";
  appimageName = "AlterSend-x86_64.AppImage";
  src = fetchurl {
    name = "${pname}-${version}.AppImage";
    url = "https://github.com/denislupookov/altersend/releases/download/v${version}/${appimageName}";
    hash = "sha256-UtckUQP4qPLgXta2KjnRkwPGi/Rdaq2we8ersrd8I+Q=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/altersend.desktop $out/share/applications/altersend.desktop
    substituteInPlace $out/share/applications/altersend.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'

    install -m 444 -D ${appimageContents}/altersend.png \
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
