{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.12.1";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-cUJwt4gRdlQvMnrEvYG7JZe/2oz4cN9k35TEur13Sks=";
  };

  vendorHash = "sha256-Ei2i7dQ9s42Gg6f2iLABbTG7OQspjHoRnqIhkfcNvFo=";

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
