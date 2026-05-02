{
  lib,
  rustPlatform,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  fetchFromGitHub,
  cargo-tauri,
  nodejs,
  opencode,
  chrome-devtools-mcp,
  openwork-sidecars,
  pkg-config,
  webkitgtk_4_1,
  wrapGAppsHook3,
  gtk3,
  librsvg,
  openssl,
  autoPatchelfHook,
  libayatana-appindicator,
  jq,
  moreutils,
  stdenv,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "openwork";
  version = "0.11.202";

  src = fetchFromGitHub {
    owner = "different-ai";
    repo = "openwork";
    rev = "81efa1aceea9652aab89cf23f89c32f7f2cc4580";
    hash = "sha256-87MSTlKLMwTTMznJ8eQVT45T6KNYZvJmmf7l7Utm7Mc=";
  };

  sourceRoot = "source";

  pnpmDeps = fetchPnpmDeps {
    pname = "openwork-pnpm-deps";
    version = finalAttrs.version;
    src = finalAttrs.src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-6Wk2+/g9lKURmebBtaFa1Rqd5OOlBLTctWjIo4B0lqI=";
  };

  cargoRoot = "apps/desktop/src-tauri";
  cargoHash = "sha256-k7NAvLqJep25qYyJSaqFXwmpWD38JvzdAVq/671zDAI=";

  buildAndTestSubdir = "apps/desktop/src-tauri";

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    pnpmConfigHook
    pnpm_10
    pkg-config
    wrapGAppsHook3
    autoPatchelfHook
    jq
    moreutils
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    webkitgtk_4_1
    gtk3
    librsvg
    openssl
    libayatana-appindicator
  ];

  postPatch = ''
    substituteInPlace apps/desktop/src-tauri/tauri.conf.json \
      --replace-fail '"createUpdaterArtifacts": true' '"createUpdaterArtifacts": false'

    jq 'del(.plugins."deep-link")' apps/desktop/src-tauri/tauri.conf.json | sponge apps/desktop/src-tauri/tauri.conf.json

    jq 'del(.build.beforeBuildCommand)' apps/desktop/src-tauri/tauri.conf.json | sponge apps/desktop/src-tauri/tauri.conf.json

    jq 'del(.packageManager)' package.json | sponge package.json
  '';

  preBuild = ''
    export HOME=$(mktemp -d)

    SIDECAR_DIR="$PWD/apps/desktop/src-tauri/sidecars"
    mkdir -p "$SIDECAR_DIR"

    ln -s ${opencode}/bin/.opencode-wrapped "$SIDECAR_DIR/opencode"
    ln -s ${opencode}/bin/.opencode-wrapped "$SIDECAR_DIR/opencode-x86_64-unknown-linux-gnu"

    ln -s ${openwork-sidecars}/bin/openwork-server "$SIDECAR_DIR/openwork-server"
    ln -s ${openwork-sidecars}/bin/openwork-server "$SIDECAR_DIR/openwork-server-x86_64-unknown-linux-gnu"
    ln -s ${openwork-sidecars}/bin/opencode-router "$SIDECAR_DIR/opencode-router"
    ln -s ${openwork-sidecars}/bin/opencode-router "$SIDECAR_DIR/opencode-router-x86_64-unknown-linux-gnu"
    ln -s ${openwork-sidecars}/bin/openwork-orchestrator "$SIDECAR_DIR/openwork-orchestrator"
    ln -s ${openwork-sidecars}/bin/openwork-orchestrator "$SIDECAR_DIR/openwork-orchestrator-x86_64-unknown-linux-gnu"

    ln -s ${lib.getExe chrome-devtools-mcp} "$SIDECAR_DIR/chrome-devtools-mcp"
    ln -s ${lib.getExe chrome-devtools-mcp} "$SIDECAR_DIR/chrome-devtools-mcp-x86_64-unknown-linux-gnu"

    (cd apps/app && ../../node_modules/.pnpm/node_modules/.bin/vite build)

    HASH_opencode=$(sha256sum "$SIDECAR_DIR/opencode" | cut -d' ' -f1)
    HASH_server=$(sha256sum "$SIDECAR_DIR/openwork-server" | cut -d' ' -f1)
    HASH_router=$(sha256sum "$SIDECAR_DIR/opencode-router" | cut -d' ' -f1)
    HASH_orchestrator=$(sha256sum "$SIDECAR_DIR/openwork-orchestrator" | cut -d' ' -f1)
    HASH_cdp=$(sha256sum "$SIDECAR_DIR/chrome-devtools-mcp" | cut -d' ' -f1)

    VERSIONS="{
      \"opencode\": { \"version\": \"${opencode.version}\", \"sha256\": \"$HASH_opencode\" },
      \"openwork-server\": { \"version\": \"${finalAttrs.version}\", \"sha256\": \"$HASH_server\" },
      \"opencodeRouter\": { \"version\": \"${finalAttrs.version}\", \"sha256\": \"$HASH_router\" },
      \"openwork-orchestrator\": { \"version\": \"${finalAttrs.version}\", \"sha256\": \"$HASH_orchestrator\" },
      \"chrome-devtools-mcp\": { \"version\": \"${chrome-devtools-mcp.version}\", \"sha256\": \"$HASH_cdp\" }
    }"
    echo "$VERSIONS" > "$SIDECAR_DIR/versions.json"
    echo "$VERSIONS" > "$SIDECAR_DIR/versions.json-x86_64-unknown-linux-gnu"
  '';

  doCheck = false;

  dontAutoPatchelf = true;
  dontStrip = true;

  postFixup = ''
    autoPatchelf --no-recurse -- $out/bin/.OpenWork-Dev-wrapped

    rm -f $out/bin/opencode $out/bin/.opencode-wrapped
  '';

  runtimeDependencies = lib.optionals stdenv.hostPlatform.isLinux [
    libayatana-appindicator
    opencode
    chrome-devtools-mcp
  ];

  meta = with lib; {
    description = "OpenWork - AI coworker for teams";
    homepage = "https://github.com/different-ai/openwork";
    license = licenses.mit;
    mainProgram = "OpenWork-Dev";
    platforms = platforms.linux;
  };
})
