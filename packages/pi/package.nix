{
  lib,
  buildNpmPackage,
  fetchurl,
  fetchFromGitHub,
  linkFarm,
  makeBinaryWrapper,
  nodejs_22,
  ripgrep,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  writeText,
}:
let
  version = "0.81.1";
  hash = "sha256-xo3uoR7HceOCL3wqoMcacOe8WXP1o7ReAXne5t6Hgao=";
  modelDataHash = "sha256-x53MD5DU370ZdNoz36P+OWZjGVpoM5sfVcEU2/ckDy8=";
  npmDepsHash = "sha256-8TrTDYpgobFRVXalfBoLkKV/DZlzUMYoyWgYXW9tIlo=";

  themeFiles = lib.mapAttrs (name: definition: writeText "${name}.json" (builtins.toJSON definition)) (import ./themes);
  themes = linkFarm "pi-themes-${version}" (
    lib.mapAttrsToList (name: path: {
      name = "${name}.json";
      inherit path;
    }) themeFiles
  );
  extensionDefinitions = import ./extensions;
  extensions = linkFarm "pi-extensions-${version}" (
    lib.mapAttrsToList (name: definition: {
      inherit name;
      path = definition.source;
    }) extensionDefinitions
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
    node --experimental-strip-types --test ${./extensions/web-tools}/test/*.test.ts

    mkdir -p packages/ai/src/providers
    tar -xzf ${modelData} \
      --strip-components=3 \
      -C packages/ai/src/providers \
      package/dist/providers/data
  '';

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

    mkdir -p "$out/share/pi/themes"
    cp -r ${themes}/. "$out/share/pi/themes/"

    mkdir -p "$out/share/pi/extensions"
    cp -r ${extensions}/. "$out/share/pi/extensions/"

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

  passthru = {
    inherit
      extensionDefinitions
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
