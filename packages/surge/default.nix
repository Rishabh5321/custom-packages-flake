{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-BTcqr4o9vizUz0Hcm9kXWcBJoRhzQpwc8v0TTiZZtdc=";
  };

  vendorHash = "sha256-uZrSOcwfXJ9LwuHi+0wIjPBIsAdULU60GbWrJNV923s=";

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
