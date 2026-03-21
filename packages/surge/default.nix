{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-nI8rPN7XDOEQQFiP/DlfK1TgMNMXXIv166uZDzJrOsc=";
  };

  vendorHash = "sha256-zaQPmtzGfdj959Mi0Zt1R097XkZFbtJspcYry4SkpEg=";

  preCheck = ''
    export HOME=$(mktemp -d)
  '';



  meta = with lib; {
    description = "Surge - Open-source TUI Downloader";
    homepage = "https://github.com/surge-downloader/surge";
    license = licenses.mit;
    maintainers = with maintainers; [ Rishabh5321 ];
    mainProgram = "surge";
  };
}
