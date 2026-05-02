{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage {
  pname = "chrome-devtools-mcp";
  version = "0.20.2";

  src = fetchFromGitHub {
    owner = "ChromeDevTools";
    repo = "chrome-devtools-mcp";
    rev = "62791770169c2ce3a2fab807de11f767de26a503";
    hash = "sha256-u1jCmWvRcSj2DCN5EFSGvwxlPsRbnFOt1DTi9F2fgTM=";
  };

  npmDepsHash = "sha256-eJI8DeQ55F7D3eER4ae1ZA/n6rF+NzsY9Tm0TGycwyw=";

  env.PUPPETEER_SKIP_DOWNLOAD = "true";

  npmBuildScript = "bundle";

  preBuild = ''
    sed -i '/ModelUpdateEvent\.eventName.*:.*ModelUpdateEvent/d' \
      node_modules/chrome-devtools-frontend/front_end/models/trace/ModelImpl.ts
  '';

  meta = {
    description = "Chrome DevTools MCP server for AI coding agents";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
