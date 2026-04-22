{ fetchurl
, appimageTools
, lib
, extraPkgs ? [ ]
, makeWrapper
, glib-networking
, gst_all_1
, cacert
, adwaita-icon-theme
, shared-mime-info
, gsettings-desktop-schemas
, gtk3
, ...
}:
let
  pname = "anymex";
  version = "3.0.7";
  src = fetchurl {
    url = "https://github.com/RyanYuuki/AnymeX/releases/download/v${version}/AnymeX-Linux.AppImage";
    hash = "sha256-pcgKZWSorpcrAshSI38EWpsnxKA3GgMwPToLx+rr+P8=";
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
      libglvnd
      libxkbcommon
      at-spi2-atk
      webkitgtk_4_1
      gtk3
      libsoup_3
      glib-networking
      openssl
      gsettings-desktop-schemas
      adwaita-icon-theme
      shared-mime-info
      dconf
      libsecret
      libnotify
      nss
      nspr
      cacert
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
      substituteInPlace $out/share/applications/*.desktop \
        --replace-fail 'Exec=usr/bin/anymex' 'Exec=${pname}' || \
      substituteInPlace $out/share/applications/*.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      mkdir -p $out/share/pixmaps
      cp ${appimageContents}/*.png $out/share/pixmaps/

      wrapProgram $out/bin/${pname} \
        --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPaths}" \
        --set WEBKIT_DISABLE_COMPOSITING_MODE "1" \
        --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
        --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-data-schemas/${gsettings-desktop-schemas.name}" \
        --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-data-schemas/${gtk3.name}" \
        --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share" \
        --prefix XDG_DATA_DIRS : "${shared-mime-info}/share"
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
