{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.5.4";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-FRuVgj0GXLfvy7Dj272XQO6cs2D8ePQ/PcGMZNUaxfo=";
  };

  vendorHash = "sha256-IGVt/HanZHglYSZ8WASrzqvTZZtK/bJpJzXNVqSqUfE=";

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
