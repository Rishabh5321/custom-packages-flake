{ lib
, fetchurl
, appimageTools
, ffmpeg
}:

let
  pname = "stremio-enhanced";
  version = "1.1.5";
  src = fetchurl {
    url = "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}.AppImage";
    hash = "sha256-ATy2ekUWGI3s+CtQemQ2hXOe7etk56hXHWarWC607GA=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    ffmpeg
  ];

  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname} || true
    
    if [ -f ${appimageContents}/stremio.desktop ]; then
      install -m 444 -D ${appimageContents}/stremio.desktop $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=stremio' 'Exec=${pname}' \
        --replace-fail 'Icon=stremio' 'Icon=${pname}' \
        --replace-fail 'Name=Stremio' 'Name=Stremio Enhanced'
    fi

    if [ -f ${appimageContents}/stremio.png ]; then
      install -m 444 -D ${appimageContents}/stremio.png \
        $out/share/icons/hicolor/512x512/apps/${pname}.png
    fi
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
