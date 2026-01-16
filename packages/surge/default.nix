{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-yiBr7JsRkuVfhf0YcZLXIj8NkfFQS00W8uodDGdDLFk=";
  };

  vendorHash = "sha256-SO2mOZZ6We3XXtpnaIvVchqFy/x07k+tvJ25sTxQxXU=";

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
