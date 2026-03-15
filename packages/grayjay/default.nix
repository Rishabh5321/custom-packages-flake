{ buildDotnetModule
, fetchFromGitLab
, fetchurl
, dotnetCorePackages
, buildNpmPackage
, lib
, libz
, icu
, openssl
, libgbm
, libxrandr
, libxfixes
, libxext
, libxdamage
, libxcomposite
, libx11
, libxcb
, gtk3
, glib
, nss
, nspr
, dbus
, atk
, cups
, curl
, libdrm
, expat
, libxkbcommon
, pango
, cairo
, udev
, alsa-lib
, libGL
, libsecret
, nix-update-script
, autoPatchelfHook
, unzip
, makeDesktopItem
, copyDesktopItems
, libgcc
, krb5
, wrapGAppsHook3
, _experimental-update-script-combinators
,
}:
let
  version = "18";
  src = fetchFromGitLab {
    domain = "gitlab.futo.org";
    owner = "videostreaming";
    repo = "Grayjay.Desktop";
    tag = version;
    hash = "sha256-dhXUjj9x8v1bfHLPxNtcysj/eKeT3kkSeVuX6PKoykE=";
    fetchSubmodules = true;
    fetchLFS = true;
  };
  justCefNative = fetchurl {
    url = "https://static.grayjay.app/justcef/1/JustCefNative-linux-x64.zip";
    hash = "sha256-LXOp+QZZcWBd8eP+BpK++AMBo9303+aIDEEYNVWekhE=";
  };
  frontend = buildNpmPackage {
    pname = "grayjay-frontend";
    inherit version src;

    sourceRoot = "source/Grayjay.Desktop.Web";

    npmBuildScript = "build";
    npmDepsHash = "sha256-3yJIPkuEvkFL9Wb4y/r0yEULQbXx/wHqicFBLzOPj68=";

    installPhase = ''
      runHook preInstall
      cp -r dist/ $out
      runHook postInstall
    '';
  };
in
buildDotnetModule (finalAttrs: {
  pname = "grayjay";

  inherit version src frontend;

  buildInputs = [
    openssl
    libgbm
    libgcc
    libx11
    gtk3
    glib
    curl
    alsa-lib
    nspr
    nss
    icu
    krb5
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    copyDesktopItems
    unzip
  ];

  dontWrapGApps = true;

  desktopItems = [
    (makeDesktopItem {
      name = "Grayjay";
      exec = "Grayjay";
      icon = "grayjay";
      comment = "Cross platform media application for streaming and downloading media";
      desktopName = "Grayjay Desktop";
      categories = [ "Network" ];
    })
  ];

  projectFile = [
    "Grayjay.ClientServer/Grayjay.ClientServer.csproj"
    "Grayjay.Engine/Grayjay.Engine/Grayjay.Engine.csproj"
    "Grayjay.Desktop.CEF/Grayjay.Desktop.CEF.csproj"
    "FUTO.MDNS/FUTO.MDNS/FUTO.MDNS.csproj"
    "JustCef/JustCef.csproj"
  ];

  testProjectFile = [
    "Grayjay.Engine/Grayjay.Engine.Tests/Grayjay.Engine.Tests.csproj"
  ];

  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_9_0 // {
    inherit
      (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_9_0
        dotnetCorePackages.sdk_8_0
      ])
      packages
      targetPackages
      ;
  };
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

  executables = [ "Grayjay" ];

  preBuild = ''
    rm -r Grayjay.ClientServer/wwwroot/web
    cp -r ${frontend} Grayjay.ClientServer/wwwroot/web

    # Pre-populate JustCef native cache to avoid network download during build
    justcef_cache="JustCef/obj/justcef/net8.0/1/linux-x64"
    mkdir -p "$justcef_cache/extracted"
    cp ${justCefNative} "$justcef_cache/JustCefNative-linux-x64.zip"
    unzip -q "$justcef_cache/JustCefNative-linux-x64.zip" -d "$justcef_cache/extracted"
    # Flatten if single top-level directory
    top_count=$(find "$justcef_cache/extracted" -mindepth 1 -maxdepth 1 | wc -l)
    if [ "$top_count" = "1" ]; then
      only_entry=$(find "$justcef_cache/extracted" -mindepth 1 -maxdepth 1)
      if [ -d "$only_entry" ]; then
        tmpdir="$justcef_cache/extracted.flatten"
        mkdir -p "$tmpdir"
        mv "$only_entry"/* "$tmpdir"/
        rm -rf "$justcef_cache/extracted"
        mv "$tmpdir" "$justcef_cache/extracted"
      fi
    fi
    printf "1" > "$justcef_cache/extracted/.justcef.version"
    printf "https://static.grayjay.app/justcef/1/JustCefNative-linux-x64.zip" > "$justcef_cache/extracted/.justcef.url"
  '';

  postInstall = ''
    chmod +x $out/lib/grayjay/cef/justcefnative
    chmod +x $out/lib/grayjay/ffmpeg
    rm -f $out/lib/grayjay/Portable
    ln -s /tmp/grayjay-launch $out/lib/grayjay/launch
    ln -s /tmp/grayjay-cef-launch $out/lib/grayjay/cef/launch
    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -sf $out/lib/grayjay/grayjay.png $out/share/icons/hicolor/scalable/apps/grayjay.png
  '';

  makeWrapperArgs = [
    "--chdir"
    "${placeholder "out"}/lib/grayjay"
  ];

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  runtimeDeps = [
    libz

    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb

    dbus
    atk
    cups
    libdrm
    expat
    libxkbcommon
    pango
    cairo
    udev
    libGL
    libsecret
  ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
        "--url"
        "https://gitlab.futo.org/api/v4/projects/videostreaming%2FGrayjay%2EDesktop/repository/archive.tar.gz?sha=refs%2Ftags%2F10"
      ];
    })
    finalAttrs.passthru.fetch-deps
  ];

  meta = {
    description = "Cross-platform application to stream and download content from various sources";
    longDescription = ''
      Grayjay is a cross-platform application that enables users to
      stream and download multimedia content from various online sources,
      most prominently YouTube.
      It also offers an extensible plugin API to create and import new
      integrations.
    '';
    homepage = "https://grayjay.app/desktop/";
    license = lib.licenses.sfl;
    maintainers = with lib.maintainers; [
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "Grayjay";
  };
})
