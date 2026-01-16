{ pkgs }:

let
  mkThorium = { pname, version, url, variant, hash }:
    let
      src = pkgs.fetchurl { inherit url hash; };
      appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
    in
    pkgs.appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/thorium-browser.desktop $out/share/applications/thorium-browser.desktop
        install -m 444 -D ${appimageContents}/thorium.png $out/share/icons/hicolor/512x512/apps/thorium.png
        substituteInPlace $out/share/applications/thorium-browser.desktop \
          --replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'
      '';

      meta = with pkgs.lib; {
        description = "Thorium Browser (${variant}) - A fast and secure web browser";
        homepage = "https://thorium.rocks";
        license = licenses.bsd3;
        maintainers = with maintainers; [ Alex313031 ];
        platforms = [ "x86_64-linux" ];
        mainProgram = "thorium";
      };
    };
in
{
  thorium-avx = mkThorium {
    pname = "thorium";
    version = "130.0.6723.174";
    variant = "AVX";
    url = "https://github.com/Alex313031/thorium/releases/download/M130.0.6723.174/Thorium_Browser_130.0.6723.174_AVX.AppImage";
    hash = "sha256-23Vq+MDoV1ePkcVVy5SHWX6QovFUKxDdsgteWfG/i1U="; # Replace with the actual hash
  };
  thorium-avx2 = mkThorium {
    pname = "thorium";
    version = "130.0.6723.174";
    variant = "AVX2";
    url = "https://github.com/Alex313031/thorium/releases/download/M130.0.6723.174/Thorium_Browser_130.0.6723.174_AVX2.AppImage";
    hash = "sha256-Ej7OIdAjYRmaDlv56ANU5pscuwcBEBee6VPZA3FdxsQ=";
  };
  thorium-sse3 = mkThorium {
    pname = "thorium";
    version = "130.0.6723.174";
    variant = "SSE3";
    url = "https://github.com/Alex313031/thorium/releases/download/M130.0.6723.174/Thorium_Browser_130.0.6723.174_SSE3.AppImage";
    hash = "sha256-6qHCijDhAk7gXJ2TM774gVgW82AhexFlXFG1C0kfFoc=";
  };
  thorium-sse4 = mkThorium {
    pname = "thorium";
    version = "130.0.6723.174";
    variant = "SSE4";
    url = "https://github.com/Alex313031/thorium/releases/download/M130.0.6723.174/Thorium_Browser_130.0.6723.174_SSE4.AppImage";
    hash = "sha256-v5GGcu/bLJMc2f4Uckcn+ArgnnLL/jrT+01iw/105iY=";
  };
}
