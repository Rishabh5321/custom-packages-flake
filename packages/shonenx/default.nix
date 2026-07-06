{ lib
, stdenv
, fetchurl
, unzip
, autoPatchelfHook
, gtk3
, glib
, pango
, harfbuzz
, cairo
, gdk-pixbuf
, libepoxy
, libX11
, mpv
, curl
, makeWrapper
, libsoup_3
, webkitgtk_4_1
, libsecret
, glib-networking
, cacert
, alsa-lib
, alsa-plugins
, gst_all_1
, libglvnd
, jdk
}:

stdenv.mkDerivation rec {
  pname = "shonenx";
  version = "2.0.7";

  src = fetchurl {
    url = "https://github.com/roshancodespace/ShonenX/releases/download/v${version}/ShonenX-Linux.zip";
    sha256 = "0jhca0ywa7jmxj2fr35nkd7b589zxilsmwjv407zfcgx8w1g7a68";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    glib
    pango
    harfbuzz
    cairo
    gdk-pixbuf
    libepoxy
    libX11
    mpv
    curl
    libsoup_3
    webkitgtk_4_1
    libsecret
    glib-networking
    alsa-lib
    alsa-plugins
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    libglvnd
    jdk
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libjvm.so"
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/shonenx $out/share/applications $out/share/icons/hicolor/256x256/apps

    cp -r linux/* $out/lib/shonenx/

    chmod +x $out/lib/shonenx/shonenx

    # Fix libdartjni.so RPATH to find libjvm.so
    patchelf --add-rpath "${jdk}/lib/openjdk/lib/server" $out/lib/shonenx/lib/libdartjni.so

    # Install icon
    if [ -f "$out/lib/shonenx/data/flutter_assets/assets/icons/app_icon-modified-2.png" ]; then
      cp "$out/lib/shonenx/data/flutter_assets/assets/icons/app_icon-modified-2.png" $out/share/icons/hicolor/256x256/apps/shonenx.png
    else
      echo "Warning: Icon not found in expected location"
    fi

    # Create desktop entry
    cat > $out/share/applications/shonenx.desktop <<EOF
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=ShonenX
    Comment=Anime Streaming Desktop
    Exec=shonenx
    Icon=shonenx
    Terminal=false
    Categories=Video;AudioVideo;Player;
    StartupWMClass=shonenx
    EOF

    makeWrapper $out/lib/shonenx/shonenx $out/bin/shonenx \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ mpv libglvnd alsa-lib gst_all_1.gstreamer gst_all_1.gst-plugins-base gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad ]}:$out/lib/shonenx/lib:"${jdk}/lib/openjdk/lib/server" \
      --prefix PATH : ${lib.makeBinPath [ mpv curl ]} \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
      --set ALSA_PLUGIN_DIR "${alsa-plugins}/lib/alsa-lib" \
      --run "cd $out/lib/shonenx"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Anime Streaming Desktop App";
    homepage = "https://github.com/roshancodespace/ShonenX";
    license = licenses.gpl3; # Assuming GPL3 based on typical projects or need verification, but leaving generic if unknown
    platforms = [ "x86_64-linux" ];
    mainProgram = "shonenx";
  };
}
