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
, libxkbcommon
, libdrm
, pixman
, udev
, seatd
, waydroid
, runtimeShell
, libGL
, mesa
, libgbm
, libx11
, libxcb-wm
, libxcb-render-util
, libxcb-errors
, vulkan-loader
, vulkan-headers
, glslang
, hwdata
, libdisplay-info
, libliftoff
, libinput
, lcms2              # <--- Added lcms2 here
, systemd
, nix-update-script
}:

stdenv.mkDerivation rec {
  pname = "cage-xtmapper";
  version = cageVersion;
  tag = "v20260208";

  cageVersion = "0.2.0";
  wlrootsVersion = "0.18.1";

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
    glslang
  ];

  buildInputs = [
    wayland
    wayland-protocols
    libxcb
    libxkbcommon
    libdrm
    pixman
    udev
    seatd
    libinput
    systemd

    # X11 / XWayland backend dependencies
    libx11
    libxcb-wm
    libxcb-render-util
    libxcb-errors

    # Renderers and display logic
    libGL
    mesa
    libgbm
    vulkan-loader
    vulkan-headers
    hwdata
    libdisplay-info
    libliftoff
    lcms2 # <--- Added lcms2 here
  ];

  NIX_CFLAGS_COMPILE = [ "-Wno-error" ];

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

  mesonFlags = [
    "--buildtype=release"
    "-Ddefault_library=static"
    "-Dwlroots:renderers=gles2,vulkan"
  ];

  postInstall = ''
    install -Dm755 "$src/cage_xtmapper.sh" "$out/bin/cage_xtmapper.sh"
    substituteInPlace "$out/bin/cage_xtmapper.sh" \
      --replace-fail /bin/bash "${runtimeShell}"

    rm -rf $out/lib $out/include

    wrapProgram $out/bin/cage_xtmapper.sh \
      --prefix PATH : "${lib.makeBinPath [ waydroid ]}:$out/bin"
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
