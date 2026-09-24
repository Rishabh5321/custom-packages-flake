{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.12.2";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-LojzHquVeXAI8/k5qYSdGExWw/Y6sgVRNjNagRot5gY=";
  };

  vendorHash = "sha256-Z1eNKci0MzXvKs49kOEYXr/JEO7AJB9kHdFTyNbxkw4=";

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
