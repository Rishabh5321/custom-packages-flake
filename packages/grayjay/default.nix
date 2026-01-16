{ pkgs, lib, ... }:

let
  # Base Grayjay derivation - extracts the zip file
  grayjay-base = pkgs.stdenv.mkDerivation {
    name = "grayjay-base";
    src = pkgs.fetchurl {
      url = "https://updater.grayjay.app/Apps/Grayjay.Desktop/Grayjay.Desktop-linux-x64.zip";
      sha256 = "081qmk3yxifk1623dyfdwdla77rcy6qg6hkps5miqb3rnc1plh83";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    installPhase = ''
      # Extract the .zip file to $out/share/grayjay
      mkdir -p $out/share/grayjay
      unzip $src -d $out/share/grayjay

      # Ensure the Grayjay executable exists
      GRAYJAY_EXECUTABLE="$out/share/grayjay/Grayjay.Desktop-linux-x64-v13/Grayjay"
      if [ ! -f "$GRAYJAY_EXECUTABLE" ]; then
        echo "Error: Grayjay executable not found in the extracted files!"
        exit 1
      fi

      # Check for FUTO.Updater.Client in the same directory
      FUTO_UPDATER="$out/share/grayjay/Grayjay.Desktop-linux-x64-v13/FUTO.Updater.Client"
      if [ ! -f "$FUTO_UPDATER" ]; then
        echo "Warning: FUTO.Updater.Client not found in the extracted files!"
      else
        chmod +x "$FUTO_UPDATER"
      fi

      # Make the executable and create a symlink in $out/bin
      chmod +x "$GRAYJAY_EXECUTABLE"

      # Copy the icon to the share directory
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp "$out/share/grayjay/Grayjay.Desktop-linux-x64-v13/grayjay.png" $out/share/icons/hicolor/256x256/apps/grayjay.png
    '';
  };

  # Desktop entry files
  grayjay-desktop-files = pkgs.runCommand "grayjay-desktop-files" { } ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/256x256/apps

    # Copy the icon to the appropriate directory
    cp "${grayjay-base}/share/icons/hicolor/256x256/apps/grayjay.png" $out/share/icons/hicolor/256x256/apps/grayjay.png

    # Grayjay desktop file
    cat > $out/share/applications/grayjay.desktop << EOF
    [Desktop Entry]
    Name=Grayjay
    Type=Application
    GenericName=Desktop Client for Grayjay
    Comment=A desktop client for Grayjay to stream and download video content
    Icon=grayjay
    Exec=grayjay
    Terminal=false
    Categories=Network;
    Keywords=YouTube;Player;
    StartupNotify=true
    StartupWMClass=Grayjay
    EOF
  '';

  # FHS environment
  grayjay-fhs = pkgs.buildFHSEnv {
    name = "grayjay-fhs";
    targetPkgs = pkgs: with pkgs; [
      # Dependencies for both Grayjay and FUTO Updater
      libgbm
      libz
      icu
      openssl
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      gtk3
      glib
      nss
      nspr
      dbus
      atk
      cups
      libdrm
      expat
      libxkbcommon
      pango
      cairo
      udev
      alsa-lib
      mesa
      libGL
      libsecret
      dotnet-runtime
      curl
    ];

    # Set environment variables and copy files to a writable directory
    runScript = ''
      # Create a writable directory for Grayjay's runtime files
      export GRAYJAY_DATA_DIR="$HOME/.grayjay"
      mkdir -p "$GRAYJAY_DATA_DIR"

      # Copy the entire Grayjay.Desktop-linux-x64-v13 directory to the writable directory
      GRAYJAY_SRC_DIR="${grayjay-base}/share/grayjay/Grayjay.Desktop-linux-x64-v13"
      GRAYJAY_DEST_DIR="$GRAYJAY_DATA_DIR/Grayjay.Desktop-linux-x64-v13"

      if [ ! -d "$GRAYJAY_DEST_DIR" ] || [ "$GRAYJAY_SRC_DIR" -nt "$GRAYJAY_DEST_DIR" ]; then
        # Create the destination directory if it doesn't exist
        mkdir -p "$GRAYJAY_DEST_DIR"
        # Copy and overwrite contents from source to destination
        cp -rT "$GRAYJAY_SRC_DIR" "$GRAYJAY_DEST_DIR"
        # Ensure the destination directory is writable by the user
        chmod -R u+w "$GRAYJAY_DEST_DIR"
      fi

      # Check if FUTO.Updater.Client exists
      FUTO_UPDATER="$GRAYJAY_DEST_DIR/FUTO.Updater.Client"
      if [ ! -f "$FUTO_UPDATER" ]; then
        echo "Warning: FUTO.Updater.Client not found!"
      else
        chmod +x "$FUTO_UPDATER"
      fi

      # Check if we should run the updater or the app
      if [ "$1" = "updater" ]; then
        # Run FUTO Updater if it exists
        if [ -f "$FUTO_UPDATER" ]; then
          cd "$GRAYJAY_DEST_DIR"
          shift  # Remove the "updater" argument
          exec ./FUTO.Updater.Client "$@"
        else
          echo "Error: FUTO.Updater.Client not found!"
          exit 1
        fi
      else
        # Run Grayjay with updater check
        cd "$GRAYJAY_DEST_DIR"

        # Launch the FUTO Updater in background first to check for updates if it exists
        if [ -f "$FUTO_UPDATER" ]; then
          "$FUTO_UPDATER" --check-updates &
        fi

        # Then launch Grayjay with any passed arguments
        exec ./Grayjay "$@"
      fi
    '';
  };

  # Main Grayjay FHS wrapper
  grayjay-fhs-wrapper = pkgs.writeShellScriptBin "grayjay" ''
    # Execute the FHS environment with appropriate arguments
    exec ${grayjay-fhs}/bin/grayjay-fhs ''${RUN_UPDATER:+updater} "''${ARGS[@]}"
  '';

in
pkgs.symlinkJoin {
  name = "grayjay";
  paths = [
    grayjay-fhs-wrapper
    grayjay-desktop-files
  ];
  meta = with lib; {
    description = "Desktop client for Grayjay with integrated FUTO Updater";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
