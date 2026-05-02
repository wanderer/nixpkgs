{
  lib,
  stdenv,
  bun,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openwork-sidecars";
  version = "0.11.202";

  src = fetchFromGitHub {
    owner = "different-ai";
    repo = "openwork";
    rev = "81efa1aceea9652aab89cf23f89c32f7f2cc4580";
    hash = "sha256-87MSTlKLMwTTMznJ8eQVT45T6KNYZvJmmf7l7Utm7Mc=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-6Wk2+/g9lKURmebBtaFa1Rqd5OOlBLTctWjIo4B0lqI=";
  };

  nativeBuildInputs = [
    bun
    pnpmConfigHook
    pnpm_10
  ];

  dontStrip = true;

  buildPhase = ''
    export HOME=$(mktemp -d)

    (cd apps/server && bun ./script/build.ts --outdir $out/bin --filename openwork-server)
    (cd apps/opencode-router && bun ./script/build.ts --outdir $out/bin --filename opencode-router)
    (cd apps/orchestrator && NODE_ENV=production BUN_ENV=production bun ./script/build.ts --outdir $out/bin --filename openwork-orchestrator)
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    chmod +x $out/bin/openwork-server
    chmod +x $out/bin/opencode-router
    chmod +x $out/bin/openwork-orchestrator
    runHook postInstall
  '';

  meta = {
    description = "OpenWork sidecar binaries (server, router, orchestrator)";
    homepage = "https://github.com/different-ai/openwork";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
