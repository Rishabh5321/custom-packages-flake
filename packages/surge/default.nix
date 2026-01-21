{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "surge";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "surge-downloader";
    repo = "surge";
    rev = "v${version}";
    hash = "sha256-eb1sUQA1bnsb9S9RXhvNRJROhWEDXhCgdLR/1jsgorw=";
  };

  vendorHash = "sha256-V9SEj/kI8VKB20RT7qkBb95ozecYwzGsOgHIUxB19lw=";

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
