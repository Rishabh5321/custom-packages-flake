{ appimageTools, fetchurl }:
let
  pname = "mangayomi";
  version = "0.7.70";
  src = fetchurl {
    name = "${pname}-${version}.AppImage";
    url = "https://github.com/kodjodevf/mangayomi/releases/download/v${version}/Mangayomi-v${version}-linux.AppImage";
    sha256 = "sha256-XL6lSLkEG4BzjmmIY7lU25kyKsGHO6y/6k9/koRXnn4=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname} || true
    
    # Try to install desktop and icon files if they exist in the AppImage
    if [ -f ${appimageContents}/mangayomi.desktop ]; then
      install -m 444 -D ${appimageContents}/mangayomi.desktop $out/share/applications/mangayomi.desktop
      substituteInPlace $out/share/applications/mangayomi.desktop \
        --replace-fail 'Exec=/usr/bin/mangayomi' 'Exec=${pname}' || \
      substituteInPlace $out/share/applications/mangayomi.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    fi
    
    if [ -f ${appimageContents}/mangayomi.png ]; then
      install -m 444 -D ${appimageContents}/mangayomi.png \
        $out/share/icons/hicolor/512x512/apps/mangayomi.png
    fi
  '';
}
