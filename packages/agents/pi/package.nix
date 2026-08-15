{
  lib,
  buildNpmPackage,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  makeBinaryWrapper,
  nodejs_22,
  ripgrep,
  runCommand,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  writeText,
}:
let
  version = "0.84.2";
  hash = "sha256-d29ft9otYxdHRWYIAX8KMHPpppToX9ME5LbPb1rPcYo=";
  modelDataHash = "sha256-AmJ4Wnaw6y7sWWzYp6su4j7vidLvG7EhHE8KGUTaz0E=";
  npmDepsHash = "sha256-23Z/SwEnwriAmWiP+4TUG9k6P5+RSTvjL7mhRPwWk98=";

  themeFiles = lib.mapAttrs (name: definition: writeText "${name}.json" (builtins.toJSON definition)) (import ./themes);
  themes = linkFarm "pi-themes-${version}" (
    lib.mapAttrsToList (name: path: {
      name = "${name}.json";
      inherit path;
    }) themeFiles
  );
  extensionDefinitions = import ./extensions;
  extensionChecksDefinition = import ./extensions/checks.nix;
  extensionChecks = buildNpmPackage {
    pname = "pi-extension-checks";
    version = "0.1.0";
    src = ./extensions;
    npmDepsHash =
      if extensionChecksDefinition.npmDepsHash == "" then lib.fakeHash else extensionChecksDefinition.npmDepsHash;
    nodejs = nodejs_22;
    npmRebuildFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      npm run check
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      touch "$out"
      runHook postInstall
    '';
  };
  extensionPaths = lib.mapAttrs (
    name: definition:
    if definition ? npmDepsHash then
      buildNpmPackage {
        pname = "pi-extension-${name}";
        version = "0.1.0";
        src = definition.source;
        npmDepsHash = if definition.npmDepsHash == "" then lib.fakeHash else definition.npmDepsHash;
        nodejs = nodejs_22;
        npmRebuildFlags = [ "--ignore-scripts" ];
        dontNpmBuild = true;
        doCheck = true;
        checkPhase = ''
          runHook preCheck
          npm run check
          runHook postCheck
        '';
        installPhase = ''
          runHook preInstall
          npm prune --omit=dev --ignore-scripts --offline
          mkdir -p "$out"
          cp -r . "$out/"
          runHook postInstall
        '';
      }
    else
      runCommand "pi-extension-${name}-0.1.0" { } ''
        test -e ${extensionChecks}
        mkdir -p "$out"
        cp -r ${definition.source}/. "$out/"
      ''
  ) extensionDefinitions;
  extensions = linkFarm "pi-extensions-${version}" (
    lib.mapAttrsToList (name: path: {
      inherit name;
      inherit path;
    }) extensionPaths
  );

  # Upstream generates this data before publishing and excludes it from git.
  modelData = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${version}.tgz";
    hash = modelDataHash;
  };
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

  preBuild = ''
    mkdir -p packages/ai/src/providers
    tar -xzf ${modelData} \
      --strip-components=3 \
      -C packages/ai/src/providers \
      package/dist/providers/data
  '';

  buildPhase = ''
    runHook preBuild

    npx tsgo -p packages/telemetry/tsconfig.build.json
    npx tsgo -p packages/ai/tsconfig.build.json
    npx tsgo -p packages/tui/tsconfig.build.json
    npx tsgo -p packages/agent/tsconfig.build.json
    npx tsgo -p packages/protocol/tsconfig.build.json
    npx tsgo -p packages/client/tsconfig.build.json
    npm run build --workspace=packages/coding-agent

    runHook postBuild
  '';

  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"

    mkdir -p "$out/share/pi/themes"
    cp -r ${themes}/. "$out/share/pi/themes/"

    mkdir -p "$out/share/pi/extensions"
    cp -r ${extensions}/. "$out/share/pi/extensions/"

    for src in packages/ai packages/agent packages/client packages/protocol packages/telemetry packages/tui; do
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

  passthru = {
    inherit
      extensionDefinitions
      extensionChecks
      extensionPaths
      extensions
      themeFiles
      themes
      ;
  };

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev/";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
