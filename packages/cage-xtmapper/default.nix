{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
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
, lcms2
, systemd
}:

stdenv.mkDerivation rec {
  pname = "cage-xtmapper";
  version = cageVersion;
  tag = "v20261019";

  cageVersion = "0.3.0";
  wlrootsVersion = "0.20.2";

  src = fetchFromGitHub {
    owner = "Xtr126";
    repo = "cage-xtmapper";
    rev = tag;
    hash = "sha256-EGEV6DAxt32qCRY87FwJXy8skbHIxAqlh+ZtgX9x2/0=";
    fetchSubmodules = true;
  };

  sourceRoot = "source/forks/cage";

  postUnpack = ''
    mkdir -p "$sourceRoot/subprojects"
    cp -r source/forks/wlroots-xtmapper "$sourceRoot/subprojects/wlroots"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
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
    lcms2
  ];

  NIX_CFLAGS_COMPILE = [ "-Wno-error" ];

  mesonFlags = [
    "--buildtype=release"
    "-Ddefault_library=static"
    "-Dwlroots:renderers=gles2,vulkan"
  ];

  postInstall = ''
    install -Dm755 "$src/cage_xtmapper.sh" "$out/bin/cage_xtmapper.sh"

    rm -rf "$out/lib" "$out/include"

    wrapProgram "$out/bin/cage_xtmapper.sh" \
      --prefix PATH : "${lib.makeBinPath [ waydroid ]}:$out/bin"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Wayland kiosk compositor (cage) patched to run XtMapper on Waydroid";
    homepage = "https://github.com/Xtr126/cage-xtmapper";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ Rishabh5321 ];
    platforms = lib.platforms.linux;
    mainProgram = "cage_xtmapper.sh";
  };
}
