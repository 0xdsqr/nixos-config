{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs_22,
  ripgrep,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  version = "0.80.3";
  hash = "sha256-wQTrWKsb2HCGwzSAFEk8NWSDpqxSY/lv1/R6ghcmbaA=";
  npmDepsHash = "sha256-kiH6Gzbx6UM+OcZPfgxPRdOfImJR3OyqUXvmRcpKsxw=";
in
buildNpmPackage {
  pname = "pi-coding-agent";
  inherit version;

  src = fetchFromGitHub {
    owner = "earendil-works";
    repo = "pi";
    tag = "v${version}";
    inherit hash;
  };

  inherit npmDepsHash;
  npmDepsFetcherVersion = 2;

  npmWorkspace = "packages/coding-agent";
  nodejs = nodejs_22;

  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  buildPhase = ''
    runHook preBuild

    npx tsgo -p packages/ai/tsconfig.build.json
    npx tsgo -p packages/tui/tsconfig.build.json
    npx tsgo -p packages/agent/tsconfig.build.json
    npm run build --workspace=packages/coding-agent

    runHook postBuild
  '';

  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"

    for src in packages/ai packages/agent packages/tui; do
      pkg="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$src/package.json', 'utf8')).name)")"
      target="$nm/$pkg"
      rm -rf "$target"
      mkdir -p "$(dirname "$target")"
      cp -r "$src" "$target"
    done

    find "$nm" -type l -lname '*/packages/*' -delete
    find "$nm/.bin" -xtype l -delete
  '';

  postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${lib.makeBinPath [ ripgrep ]}";

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
