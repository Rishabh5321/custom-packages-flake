{ lib
, fetchurl
, appimageTools
, ffmpeg
, makeWrapper
}:

let
  pname = "stremio-enhanced";
  version = "1.2.0";
  src = fetchurl {
    url = "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}.AppImage";
    hash = "sha256-a+knxg/rd5Ied4RVK8Gg7xeFElovJab0gqxpjs11fAU=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
  serverJs = fetchurl {
    url = "https://raw.githubusercontent.com/Stremio/stremio-linux-shell/9d5ea7dc054487ec1db4fa476fafb6aa08017813/data/server.js";
    hash = "sha256-ghddeYK86GTfBx35O0s9VnpAHmWIGorFedfbDOcdr9c=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraPkgs = pkgs: with pkgs; [
    ffmpeg
  ];

  extraInstallCommands = ''
    if [ -f ${appimageContents}/stremio-enhanced.desktop ]; then
      install -m 444 -D ${appimageContents}/stremio-enhanced.desktop \
        $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname}' \
        --replace-fail 'Icon=stremio-enhanced' 'Icon=${pname}'
    fi

    if [ -f ${appimageContents}/stremio-enhanced.png ]; then
      install -m 444 -D ${appimageContents}/stremio-enhanced.png \
        $out/share/icons/hicolor/512x512/apps/${pname}.png
    fi

    install -m 444 -D ${serverJs} \
      $out/share/${pname}/streamingserver/server.js

    wrapProgram $out/bin/${pname} \
      --run 'mkdir -p "$HOME/.config/stremio-enhanced/streamingserver"' \
      --run 'test -f "$HOME/.config/stremio-enhanced/streamingserver/server.js" || cp '"${serverJs}"' "$HOME/.config/stremio-enhanced/streamingserver/server.js"' \
      --run 'mkdir -p "$HOME/.config/stremio-enhanced/plugins"'
  '';

  meta = with lib; {
    description = "Stremio Enhanced - Stremio with enhanced features";
    homepage = "https://github.com/REVENGE977/stremio-enhanced";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "stremio-enhanced";
  };
}
