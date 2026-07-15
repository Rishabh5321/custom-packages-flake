{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
, glib
, gtk3
, libX11
, libXext
, libXi
, libXrender
, libXtst
, libxkbcommon
, libGL
, dbus
, pango
, cairo
, atk
, gdk-pixbuf
, zlib
, alsa-lib
, mpv
, torrserver
, libgbm
}:

stdenv.mkDerivation rec {
  pname = "nuvio";
  version = "0.1.13-alpha";
  tag = "0.1.13-alpha";

  src = fetchurl {
    url = "https://github.com/aelrased/NuvioDesktop/releases/download/${tag}/nuvio_${version}_amd64.deb";
    hash = "sha256-RgFvkccnzq7cPjlAqBX3kZIGMiu+3hBbjVHjiCeIOVI=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gtk3
    libX11
    libXext
    libXi
    libXrender
    libXtst
    libxkbcommon
    libGL
    dbus
    pango
    cairo
    atk
    gdk-pixbuf
    zlib
    alsa-lib
    stdenv.cc.cc.lib
    mpv
    torrserver
    libgbm
  ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r opt $out/opt

        # Delete bundled video/media libraries that we resolve via Nixpkgs instead
        rm -f $out/opt/nuvio/lib/libmpv.so* \
              $out/opt/nuvio/lib/libass.so* \
              $out/opt/nuvio/lib/libplacebo.so* \
              $out/opt/nuvio/lib/libvulkan.so* \
              $out/opt/nuvio/lib/libdav1d.so* \
              $out/opt/nuvio/lib/libuchardet.so*

        # Create the custom wrapper script
        mkdir -p $out/bin
        cat > $out/bin/nuvio << EOF
    #!/usr/bin/env bash
    # Create runtime directory for TorrServer
    RUNTIME_DIR="\$HOME/.local/share/nuvio-runtime"
    mkdir -p "\$RUNTIME_DIR/native/torrserver"
    ln -sf "${torrserver}/bin/torrserver" "\$RUNTIME_DIR/native/torrserver/torrserver"

    # Set up library path including OpenGL drivers for GPU acceleration
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:${lib.makeLibraryPath [ mpv libGL libX11 libXext libXi libXrender libXtst libxkbcommon alsa-lib stdenv.cc.cc.lib libgbm ]}:\$LD_LIBRARY_PATH"

    # Set up hardware video acceleration driver paths for VA-API and VDPAU on NixOS
    export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri:\$LIBVA_DRIVERS_PATH"
    export VDPAU_DRIVER_PATH="/run/opengl-driver/lib/vdpau:\$VDPAU_DRIVER_PATH"

    # Run Nuvio from the runtime directory so it detects native/torrserver/torrserver
    cd "\$RUNTIME_DIR"
    exec "$out/opt/nuvio/bin/Nuvio" "\$@"
    EOF
        chmod +x $out/bin/nuvio

        # Install desktop entry and icons
        mkdir -p $out/share/applications $out/share/pixmaps
        cp opt/nuvio/lib/nuvio-Nuvio.desktop $out/share/applications/nuvio.desktop
        cp opt/nuvio/lib/Nuvio.png $out/share/pixmaps/nuvio.png

        substituteInPlace $out/share/applications/nuvio.desktop \
          --replace-warn "Exec=/opt/nuvio/bin/Nuvio" "Exec=nuvio" \
          --replace-warn "Icon=/opt/nuvio/lib/Nuvio.png" "Icon=nuvio" \
          --replace-warn "Icon=Nuvio" "Icon=nuvio"

        runHook postInstall
  '';

  meta = with lib; {
    description = "Nuvio Desktop client (unofficial builds with Linux fixes)";
    homepage = "https://github.com/aelrased/NuvioDesktop";
    license = licenses.gpl3Only;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [ Rishabh5321 ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "nuvio";
  };
}
