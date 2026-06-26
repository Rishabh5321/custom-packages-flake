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
}:

stdenv.mkDerivation rec {
  pname = "nuvio";
  version = "1.1.8";
  tag = "0.1.8-alpha";

  src = fetchurl {
    url = "https://github.com/aelrased/NuvioDesktop/releases/download/${tag}/nuvio_${version}_amd64.deb";
    hash = "sha256-OP2uanW/b19QsG1lYQD9B/8J9CigwFUl2uUDn1+JKyQ=";
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
  ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r opt $out/opt

        # Create the custom wrapper script
        mkdir -p $out/bin
        cat > $out/bin/nuvio << EOF
    #!/usr/bin/env bash
    # Create runtime directory for TorrServer
    RUNTIME_DIR="\$HOME/.local/share/nuvio-runtime"
    mkdir -p "\$RUNTIME_DIR/native/torrserver"
    ln -sf "${torrserver}/bin/torrserver" "\$RUNTIME_DIR/native/torrserver/torrserver"

    # Set up library path including OpenGL drivers for GPU acceleration
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:${lib.makeLibraryPath [ mpv libGL libX11 libXext libXi libXrender libXtst libxkbcommon alsa-lib stdenv.cc.cc.lib ]}:\$LD_LIBRARY_PATH"

    # Set up hardware video acceleration driver paths for VA-API and VDPAU on NixOS
    export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri:\$LIBVA_DRIVERS_PATH"
    export VDPAU_DRIVER_PATH="/run/opengl-driver/lib/vdpau:\$VDPAU_DRIVER_PATH"

    # Run Nuvio from the runtime directory so it detects native/torrserver/torrserver
    cd "\$RUNTIME_DIR"
    exec "$out/opt/nuvio/bin/Nuvio" "\$@"
    EOF
        chmod +x $out/bin/nuvio

        # Install desktop entry and icon
        mkdir -p $out/share/applications
        cp opt/nuvio/lib/nuvio-Nuvio.desktop $out/share/applications/nuvio.desktop
        substituteInPlace $out/share/applications/nuvio.desktop \
          --replace "Exec=/opt/nuvio/bin/Nuvio" "Exec=nuvio" \
          --replace "Icon=/opt/nuvio/lib/Nuvio.png" "Icon=nuvio"

        mkdir -p $out/share/pixmaps
        cp opt/nuvio/lib/Nuvio.png $out/share/pixmaps/nuvio.png

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
