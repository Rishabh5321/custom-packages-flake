{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, patch
, makeWrapper
, wayland
, wayland-scanner
, wayland-protocols
, libxcb
, libxcb-render-util
, libxkbcommon
, libdrm
, pixman
, udev
, seatd
, waydroid
, runtimeShell
, nix-update-script
}:

stdenv.mkDerivation rec {
  pname = "cage-xtmapper";
  version = cageVersion;
  tag = "v20260208";

  # Versions of the tarballs that upstream vendors inside its repository.
  cageVersion = "0.2.0";
  wlrootsVersion = "0.18.1";

  # Set by stdenv from unpackPhase below; listed here so the phases read clearly.
  sourceRoot = "cage-source/cage-${cageVersion}";

  src = fetchFromGitHub {
    owner = "Xtr126";
    repo = "cage-xtmapper";
    rev = tag;
    hash = "sha256-TUQJYjKsYHld8h7+/uI6iiwGYbs8oEc93ZE8mAczX7A=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    patch
    makeWrapper
    wayland-scanner
  ];

  # The vendored wlroots is configured by the patches for the X11 backend only,
  # so these are the libraries that end up in the resulting binary.
  buildInputs = [
    wayland
    wayland-protocols
    libxcb
    libxcb-render-util
    libxkbcommon
    libdrm
    pixman
    udev
    seatd
  ];

  # wlroots 0.18 builds with -Werror, which trips over enum values added to
  # newer libinput than wlroots 0.18 was written against.
  NIX_CFLAGS_COMPILE = [ "-Wno-error" ];

  # Reproduces upstream ./build.sh: cage and the patched wlroots are unpacked
  # from the tarballs vendored in the repository and built statically, so the
  # binary keeps the XtMapper specific wlroots patches (pointer confinement,
  # title bar toggle, forced output mode).
  unpackPhase = ''
    runHook preUnpack

    mkdir -p cage-source
    tar -C cage-source -xf "$src/cage-$cageVersion.tar.gz"

    for p in "$src"/*.patch; do
      patch -d "$sourceRoot" -p1 -i "$p"
    done

    mkdir -p "$sourceRoot/subprojects"
    tar -C "$sourceRoot/subprojects" -xf "$src/wlroots-$wlrootsVersion.tar.gz"
    rm -rf "$sourceRoot/subprojects/wlroots"
    mv "$sourceRoot/subprojects/wlroots-$wlrootsVersion" \
      "$sourceRoot/subprojects/wlroots"

    for p in "$src"/wlroots_patches/*.patch; do
      patch -d "$sourceRoot/subprojects/wlroots" -p1 -i "$p"
    done

    runHook postUnpack
  '';

  mesonBuildDir = "build";

  configurePhase = ''
    runHook preConfigure

    meson setup "$mesonBuildDir" \
      --prefix="$out" \
      --buildtype=release \
      -Ddefault_library=static

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    meson compile -C "$mesonBuildDir"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    meson install -C "$mesonBuildDir"

    install -Dm755 "$src/cage_xtmapper.sh" "$out/bin/cage_xtmapper.sh"
    substituteInPlace "$out/bin/cage_xtmapper.sh" \
      --replace-fail /bin/bash "${runtimeShell}"

    # wlroots headers and the static archive are not needed at runtime
    rm -rf $out/lib $out/include

    # The launcher script shells out to `waydroid` and to the `cage_xtmapper`
    # binary that sits next to it in this output.
    wrapProgram $out/bin/cage_xtmapper.sh \
      --prefix PATH : "${lib.makeBinPath [ waydroid ]}:$out/bin"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Wayland kiosk compositor (cage) patched to run XtMapper on Waydroid";
    homepage = "https://github.com/Xtr126/cage-xtmapper";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ Rishabh5321 ];
    platforms = lib.platforms.linux;
    mainProgram = "cage_xtmapper.sh";
  };
}
