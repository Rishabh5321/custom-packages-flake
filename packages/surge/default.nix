{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-dEr5ovvj/Tt/GqkWxMzKiYG25WrlXEt3sPqRSLhZLBU=";
  };

  vendorHash = "sha256-pkYm14M9d9Aa9HO2Z7q2aoQmkt76igLJHH+U8T7otTo=";

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  checkFlags = [ "-skip=TestSanitizeFilename" ];

  meta = with lib; {
    description = "Surge - Open-source media server for anime and manga";
    homepage = "https://github.com/surge-downloader/surge";
    license = licenses.mit;
    maintainers = with maintainers; [ Rishabh5321 ];
    mainProgram = "surge";
  };
}
