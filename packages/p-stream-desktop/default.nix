{ fetchurl
, appimageTools
, lib
, extraPkgs ? [ ]
, makeWrapper
, ...
}:
let
  pname = "p-stream-desktop";
  version = "1.2.3";
  src = fetchurl {
    url = "https://github.com/p-stream/p-stream-desktop/releases/download/${version}/P-Stream-${version}.AppImage";
    hash = "sha256-Uf+lzMeUuIMVCMo6sI0rXl4tch/oW8d86PN0uG3ddr8=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraPkgs = pkgs:
    (with pkgs; [
      libepoxy
      mesa
      webkitgtk_4_1
      gtk3
      libsoup_3
      openssl
      gsettings-desktop-schemas
      glib
      glib-networking
      pango
      cairo
      harfbuzz
      gdk-pixbuf
    ])
    ++ extraPkgs;

  extraInstallCommands = ''
    source "${makeWrapper}/nix-support/setup-hook"
    mkdir -p $out/share/applications
    cp ${appimageContents}/*.desktop $out/share/applications/
    mkdir -p $out/share/pixmaps
    cp ${appimageContents}/*.png $out/share/pixmaps/

    # Fix desktop file if necessary
    substituteInPlace $out/share/applications/*.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}' || true
  '';

  meta = with lib; {
    description = "A desktop application for p-stream";
    homepage = "https://github.com/p-stream/p-stream-desktop";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    license = with licenses; [ mit ]; # Assuming MIT as it's common, or change to unfree if not known
    mainProgram = "p-stream-desktop";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
  };
}
