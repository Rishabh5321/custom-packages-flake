{ lib
, fetchFromGitHub
, flutter
, copyDesktopItems
, makeDesktopItem
, pkg-config
, alsa-lib
, mpv-unwrapped
, libepoxy
, libdisplay-info ? null
, autoPatchelfHook
, makeWrapper
, openssl
, stdenv
, libtorrent-rasterbar
, boost
, zlib
, targetFlutterPlatform ? "linux"
,
}:

flutter.buildFlutterApplication (finalAttrs: {
  pname = "playtorrio-v2";
  version = "1.1.6";

  src = fetchFromGitHub {
    owner = "ayman708-UX";
    repo = "PlayTorrioV2";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wpohxsf0IN8n2IapGpCAfWnnBdVcecNvH4LEtH0O4w0=";
  };

  inherit targetFlutterPlatform;

  NIX_CFLAGS_COMPILE = "-Wno-error=deprecated-literal-operator -Wno-error=deprecated-declarations";

  preBuild = ''
    flutter create --platforms=linux --no-pub --project-name=play_torrio_native .
  '';

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  # gitHashes = lib.importJSON ./git-hashes.json;

  nativeBuildInputs = [ pkg-config autoPatchelfHook makeWrapper ] ++ lib.optionals (targetFlutterPlatform == "linux") [
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    mpv-unwrapped
    openssl
    stdenv.cc.cc.lib
    libtorrent-rasterbar
    boost
    zlib
  ] ++ lib.optionals (targetFlutterPlatform == "linux") [
    libepoxy
  ] ++ lib.optional (libdisplay-info != null) libdisplay-info;

  postInstall = ''
    mv $out/bin/play_torrio_native $out/bin/playtorriov2
  '';

  postFixup = ''
    wrapProgram $out/bin/playtorriov2 \
      --prefix LD_LIBRARY_PATH : "$out/app/playtorrio-v2/lib"
  '';

  desktopItems = lib.optionals (targetFlutterPlatform == "linux") [
    (makeDesktopItem {
      name = "playtorrio-v2";
      desktopName = "PlayTorrio V2";
      genericName = "Torrent Client and Player";
      exec = "playtorriov2";
      icon = "playtorriov2";
      comment = "PlayTorrio V2";
      categories = [
        "AudioVideo"
        "Video"
        "Player"
      ];
    })
  ];

  meta = {
    description = "Torrent Client and Player";
    homepage = "https://github.com/ayman708-UX/PlayTorrioV2";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "playtorriov2";
  };
})
