{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "ext-v2.1.3";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-HoNiHYH9LVJxF9ZXbjWST/6TXREjmCnt1NV9dDpKrxw=";
  };

  vendorHash = "sha256-5rlDAhs3KXq00X5NE8RGAyiS6A6TFE6j/ngYaolaY94=";

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
