{ fetchurl
, appimageTools
, lib
, extraPkgs ? [ ]
, makeWrapper
, glib-networking
, gst_all_1
, ...
}:
let
  pname = "AnymeX";
  version = "3.0.2";
  src = fetchurl {
    url = "https://github.com/RyanYuuki/AnymeX/releases/download/v${version}/AnymeX-Linux.AppImage";
    hash = "sha256-rZkuh9uJ+jx4b6b7Oe56CNm8WR6+/nCQ5Cpk43NIPLs=";
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
      webkitgtk_4_1
      gtk3
      libsoup_3
      glib-networking
      openssl
      gsettings-desktop-schemas
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      cairo
      pango
      harfbuzz
      gdk-pixbuf
      glib
    ])
    ++ extraPkgs;

  extraInstallCommands =
    let
      gstPluginPaths = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
      ];
    in
    ''
      source "${makeWrapper}/nix-support/setup-hook"
      mkdir -p $out/share/applications
      cp ${appimageContents}/*.desktop $out/share/applications/
      mkdir -p $out/share/pixmaps
      cp ${appimageContents}/*.png $out/share/pixmaps/

      wrapProgram $out/bin/${pname} \
        --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPaths}"
    '';

  meta = with lib; {
    description = "AnymeX - Your Anime & Manga Hub";
    homepage = "https://github.com/RyanYuuki/AnymeX";
    platforms = [ "x86_64-linux" ];
    license = with licenses; [ gpl3Only ];
    mainProgram = "AnymeX";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
  };
}
