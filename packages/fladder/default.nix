{ fetchurl
, appimageTools
, lib
, extraPkgs ? [ ]
, ...
}:
let
  pname = "Fladder";
  version = "0.10.2";
  src = fetchurl {
    url = "https://github.com/DonutWare/${pname}/releases/download/v${version}/${pname}-Linux-${version}.AppImage";
    hash = "sha256-wQw+o8BmUtiAbMwfDzx2oTWFDIJPf2NIlsl+KMZGV98=";
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
      lz4
    ])
    ++ extraPkgs;

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/*.desktop $out/share/applications/
    mkdir -p $out/share/pixmaps
    cp ${appimageContents}/*.png $out/share/pixmaps/
  '';

  meta = with lib; {
    description = "A Simple Jellyfin Frontend built on top of Flutter.";
    homepage = "https://github.com/DonutWare/Fladder";
    platforms = with platforms; (intersectLists x86_64 linux);
    license = with licenses; [ gpl3Only ];
    mainProgram = pname;
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
  };
}
