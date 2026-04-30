{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-dDuwuKfLk2CzMolZASbYvWVmPg3LA5uVwHQFsbQRkTw=";
  };

  vendorHash = "sha256-XHsp2zxLOh9FB93w/g24M7II0yseOUXQGLFkX9BG96A=";

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
