{ fetchurl
, appimageTools
, lib
, extraPkgs ? [ ]
, ...
}:
let
  pname = "AnymeX";
  version = "3.0.3";
  src = fetchurl {
    url = "https://github.com/RyanYuuki/AnymeX/releases/download/v${version}/AnymeX-Linux.AppImage";
    hash = "sha256-1zhiby3sabq0z32mgsa95crhh7i183v284w5yyxw2zgqpsfck0fx";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;
  extraPkgs = pkgs:
    (with pkgs; [
      mpv
      libepoxy
      libva
      mesa
    ])
    ++ extraPkgs;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/*.desktop $out/share/applications/
    mkdir -p $out/share/pixmaps
    cp ${appimageContents}/*.png $out/share/pixmaps/
  '';

  meta = with lib; {
    description = "AnymeX - Your Anime & Manga Hub";
    homepage = "https://github.com/RyanYuuki/AnymeX";
    platforms = [ "x86_64-linux" ];
    license = with licenses; [ gpl3Only ];
    mainProgram = "anymex";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
  };
}
