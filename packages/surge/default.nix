{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.6.9";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-ZCbDGfdN8Z6dxgxdJR+t3gfOY1gYnFOVyll1XYt0kes=";
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
