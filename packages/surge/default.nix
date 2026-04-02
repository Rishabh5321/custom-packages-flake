{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.7.6";

  src = fetchFromGitHub {
    owner = "SurgeDM";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-DGBZi5cK7wenCV9M1MyQM1bhFNXNaK44BPyw/cZ6+Tc=";
  };

  vendorHash = "sha256-dM0MpXdvxn7RH4USOyeIOVsdoyE4VUw+U44Qc9IkK5s=";

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
