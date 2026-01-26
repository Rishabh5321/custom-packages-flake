{ appimageTools, fetchurl }:
let
  pname = "playtorrio";
  version = "2.6.9";
  src = fetchurl {
    name = "${pname}-${version}.AppImage";
    url = "https://github.com/ayman708-UX/PlayTorrio/releases/download/v${version}/PlayTorrio.AppImage";
    sha256 = "sha256-Ap3hceuOoUlUnaYXPHkpgqpn60GqSX0Db8lN9ZO93Ww=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname} || true
    install -m 444 -D ${appimageContents}/playtorrio.desktop $out/share/applications/playtorrio.desktop
    install -m 444 -D ${appimageContents}/playtorrio.png \
      $out/share/icons/hicolor/512x512/apps/playtorrio.png
    substituteInPlace $out/share/applications/playtorrio.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';
}
