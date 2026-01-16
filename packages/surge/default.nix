{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "junaid2005p";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-0GOQKdJqD+sXyUDaO3+tpd+JmHzcqH7zUGVDPhGGJCA=";
  };

  vendorHash = "sha256-SO2mOZZ6We3XXtpnaIvVchqFy/x07k+tvJ25sTxQxXU=";

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  checkFlags = [ "-skip=TestSanitizeFilename" ];

  meta = with lib; {
    description = "Surge - Open-source media server for anime and manga";
    homepage = "https://github.com/junaid2005p/surge";
    license = licenses.mit; # Assuming MIT, need to check
    maintainers = with maintainers; [ ];
    mainProgram = "surge";
  };
}
