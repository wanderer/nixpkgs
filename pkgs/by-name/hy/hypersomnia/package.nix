{
  lib,
  llvmPackages,
  cmake,
  ninja,
  pkg-config,
  fetchgit,
  glfw,
  SDL2,
  "openal-soft",
  libpulseaudio,
  alsa-lib,
  libsodium,
  openssl,
  libglvnd,
  autoPatchelfHook,
  makeWrapper,
  wayland,
  libxkbcommon,
  xorg,
}:
llvmPackages.libcxxStdenv.mkDerivation {
  pname = "hypersomnia";
  version = "unstable-2025-03-23";

  src = fetchgit {
    url = "https://github.com/TeamHypersomnia/Hypersomnia";
    rev = "a455395a8c36bc13e36e8eae85e1dbd0fc3e7d79";
    hash = "sha256-2OCnCnwMMgrjnQM/bv7F7eRCgLG/k9DF9ohHJWfSXVY=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    llvmPackages.libllvm
    llvmPackages.lld
    llvmPackages.bintools
    llvmPackages.libcxx

    glfw
    SDL2
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    xorg.libXext
    wayland
    libxkbcommon
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilcursor
    xorg.xcbutilerrors
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm

    openal-soft
    libpulseaudio
    alsa-lib

    libsodium
    openssl

    libglvnd
  ];

  cmakeBuildDir = "build";

  cmakeFlags = [
    "-G Ninja"
    "-DARCHITECTURE=x64"
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    "-DUSE_SYSTEM_LIBDATACHANNEL=OFF"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DBUILD_UNIT_TESTS=OFF"
    "-DUSE_SDL2=ON"
  ];

  postPatch = ''
    substituteInPlace src/augs/window_framework/shell.cpp \
      --replace 'std::system(command.c_str());' '(void)std::system(command.c_str());'
  '';

  preBuild = ''
    export LD_LIBRARY_PATH="${llvmPackages.libcxx}/lib:$LD_LIBRARY_PATH"

    if [ -f cmake/build_nonsteam_integration.sh ]; then
      bash cmake/build_nonsteam_integration.sh
    fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp Hypersomnia $out/bin/Hypersomnia

    mkdir -p $out/share/hypersomnia
    cp -r $src/hypersomnia/* $out/share/hypersomnia/

    mkdir -p $out/share/applications
    install -Dm644 $src/cmake/Hypersomnia.desktop $out/share/applications/Hypersomnia.desktop

    mkdir -p $out/share/icons/hicolor/256x256/apps
    install -Dm644 $src/hypersomnia/content/gfx/metropolis_square_logo.png $out/share/icons/hicolor/256x256/apps/Hypersomnia.png

    wrapProgram $out/bin/Hypersomnia \
      --run 'DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/hypersomnia"' \
      --run 'mkdir -p "$DATA_DIR"/{logs,cache,user/demos,user/conf.d,user/downloads/arenas,user/projects}' \
      --run 'test -f "$DATA_DIR/default_config.json" || cp ${placeholder "out"}/share/hypersomnia/default_config.json "$DATA_DIR/"' \
      --run 'test -e "$DATA_DIR/content" || ln -s ${placeholder "out"}/share/hypersomnia/content "$DATA_DIR/content"' \
      --run 'test -e "$DATA_DIR/detail" || ln -s ${placeholder "out"}/share/hypersomnia/detail "$DATA_DIR/detail"' \
      --run 'cd "$DATA_DIR"' \
      --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libpulseaudio alsa-lib xorg.libXrandr xorg.libXinerama xorg.libXcursor libxkbcommon wayland SDL2 ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "The community-driven multiplayer shooter";
    longDescription = ''
      Hypersomnia is a community-driven multiplayer shooter.
      Challenge your friend to an intense duel, or gather two clans to fight a spectacular war.
      Written in modern C++, without a game engine.
    '';
    homepage = "https://hypersomnia.io";
    license = licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "Hypersomnia";
  };
}
