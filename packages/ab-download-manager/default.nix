{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, alsa-lib
, freetype
, libXtst
, libXi
, libXrender
, libXext
, libX11
, libglvnd
, wayland
, fontconfig
, gtk3
, glib
,
}:

stdenv.mkDerivation rec {
  pname = "ab-download-manager";
  version = "1.8.2";

  src = fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
    sha256 = "sha256-fyckOHrcZIBCO9kQmr48Wrg73GB9wxVENcdCF2OMFAQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    freetype
    libXtst
    libXi
    libXrender
    libXext
    libX11
    libglvnd
    wayland
    fontconfig
    gtk3
    glib
    stdenv.cc.cc.lib
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "ab-download-manager";
      desktopName = "AB Download Manager";
      genericName = "Download Manager";
      exec = "ab-download-manager %U";
      icon = "ab-download-manager";
      comment = "A Download Manager that speeds up your downloads";
      categories = [ "Network" "FileTransfer" ];
      startupWMClass = "ab-download-manager";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/ab-download-manager $out/bin
    cp -r ./* $out/opt/ab-download-manager

    # Install icon
    mkdir -p $out/share/icons/hicolor/512x512/apps
    install -Dm644 lib/ABDownloadManager.png $out/share/icons/hicolor/512x512/apps/ab-download-manager.png

    makeWrapper $out/opt/ab-download-manager/bin/ABDownloadManager $out/bin/ab-download-manager \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A Download Manager that speeds up your downloads";
    homepage = "https://abdownloadmanager.com/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "ab-download-manager";
  };
}
