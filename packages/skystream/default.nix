{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, alsa-lib
, at-spi2-atk
, cairo
, gdk-pixbuf
, glib
, gtk3
, harfbuzz
, libX11
, libepoxy
, mpv
, pango
, icu
, openssl
, jdk
,
}:

let
  icu74 = stdenv.mkDerivation rec {
    pname = "icu4c";
    version = "74.2";
    src = fetchurl {
      url = "https://github.com/unicode-org/icu/releases/download/release-${lib.replaceStrings [ "." ] [ "-" ] version}/icu4c-${lib.replaceStrings [ "." ] [ "_" ] version}-src.tgz";
      hash = "sha256-aNsIIhKpbW9T411g9H04uWLp+dIHp0z6x4Apro/14Iw=";
    };
    postPatch = ''
      patchShebangs source/configure
    '';
    preConfigure = ''
      cd source
    '';
    configureFlags = [ "--disable-debug" ];
    enableParallelBuilding = true;
    meta = with lib; {
      description = "Unicode ICU 74.2";
      homepage = "https://icu.unicode.org/";
      license = licenses.icu;
      platforms = platforms.all;
    };
  };
in
stdenv.mkDerivation rec {
  pname = "skystream";
  version = "2.3.2";

  src = fetchurl {
    url = "https://github.com/akashdh11/skystream/releases/download/v${version}/skystream-linux-x64-v${version}.tar.gz";
    hash = "sha256-eUCan802D9ZgT0cNI9N6r/ayX2CsRVm/0shL3MNpirs=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libX11
    libepoxy
    mpv
    pango
    icu74
    openssl
    jdk
    stdenv.cc.cc.lib
  ];

  runtimeDependencies = [
    "${jdk}/lib/openjdk/lib/server"
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libjvm.so"
  ];

  sourceRoot = ".";

  desktopItems = [
    (makeDesktopItem {
      name = "skystream";
      desktopName = "SkyStream";
      genericName = "Media Streamer";
      exec = "skystream";
      icon = "skystream";
      comment = "A modern, cross-platform media streaming client inspired by CloudStream";
      categories = [ "AudioVideo" "Video" "Player" ];
      startupWMClass = "skystream";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/skystream $out/bin
    cp -r ./* $out/opt/skystream

    # Install icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    # Let's try to find an icon in the extracted files
    find $out/opt/skystream -name "app_icon.png" -exec cp {} $out/share/icons/hicolor/256x256/apps/skystream.png \;
    # If not found, try any png in assets
    if [ ! -f $out/share/icons/hicolor/256x256/apps/skystream.png ]; then
      find $out/opt/skystream -name "*.png" -exec cp {} $out/share/icons/hicolor/256x256/apps/skystream.png \; -quit
    fi

    # Fix libdartjni.so RPATH to find libjvm.so
    patchelf --add-rpath "${jdk}/lib/openjdk/lib/server" $out/opt/skystream/lib/libdartjni.so

    makeWrapper $out/opt/skystream/skystream $out/bin/skystream \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (buildInputs ++ [ icu74 "${jdk}/lib/openjdk/lib/server" ])}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern, cross-platform media streaming client inspired by CloudStream";
    homepage = "https://github.com/akashdh11/skystream";
    license = licenses.mit;
    maintainers = with maintainers; [ Rishabh5321 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "skystream";
  };
}
