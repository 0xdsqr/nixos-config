{
  pkgs,
  lib,
  system,
  ...
}:
let
  version = "7.0.0-dev.20260428.1";

  preview = {
    url = "https://registry.npmjs.org/@typescript/native-preview/-/native-preview-${version}.tgz";
    hash = "sha512-JiM4PYWDGs57TT0mV2KArmaW7BnTkk3XRid79NdG17tfvDbRyg4hBCpKI7vARiQPtxjKrHlxyzxOGDpv5W5T7Q==";
  };

  platformPackages = {
    aarch64-darwin = {
      npmName = "native-preview-darwin-arm64";
      url = "https://registry.npmjs.org/@typescript/native-preview-darwin-arm64/-/native-preview-darwin-arm64-${version}.tgz";
      hash = "sha512-Lll6WmXfgTEj1G3QBIoHlabQwUtJiyhlRgSLksa06QFL5BoA7V+Lu1waa9PtPNZbGsXLDMHodtk/bRQABKuPiw==";
    };

    x86_64-linux = {
      npmName = "native-preview-linux-x64";
      url = "https://registry.npmjs.org/@typescript/native-preview-linux-x64/-/native-preview-linux-x64-${version}.tgz";
      hash = "sha512-4gJCE7wzenx1BH2Vtx2uKWUo8rFxnhGkxNEH1zxbYy/6ASwo+PnOPYmKHAzNE1C3yB5lzw71/vR5p5zyO57Y4A==";
    };

    aarch64-linux = {
      npmName = "native-preview-linux-arm64";
      url = "https://registry.npmjs.org/@typescript/native-preview-linux-arm64/-/native-preview-linux-arm64-${version}.tgz";
      hash = "sha512-cgcBX/ZBMdepkamLT8g8jQdHe7DZS/s6zTZRof6mvcrnJHlMeUnKoC9UO8/c22IrUMV3n0XPh7R8FYjUP0ll+Q==";
    };
  };

  platform = platformPackages.${system} or (throw "syncz does not support system ${system} yet");

  previewTarball = pkgs.fetchurl preview;
  platformTarball = pkgs.fetchurl { inherit (platform) url hash; };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "syncz";
  inherit version;

  src = ./.;

  nativeBuildInputs = [ pkgs.nodejs_25 ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p .deps/node_modules/@typescript
    tar -xzf ${previewTarball} -C .deps/node_modules/@typescript
    mv .deps/node_modules/@typescript/package .deps/node_modules/@typescript/native-preview

    tar -xzf ${platformTarball} -C .deps/node_modules/@typescript
    mv .deps/node_modules/@typescript/package .deps/node_modules/@typescript/${platform.npmName}

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    mkdir -p dist

    node .deps/node_modules/@typescript/native-preview/bin/tsgo.js \
      main.ts \
      cli.ts \
      commands.ts \
      --outDir dist \
      --module node16 \
      --moduleResolution node16 \
      --target es2024

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/syncz/dist" "$out/bin"
    cp package.json main.ts cli.ts commands.ts "$out/lib/syncz/"
    cp dist/*.js "$out/lib/syncz/dist/"

    cat > "$out/bin/syncz" <<EOF
    #!${pkgs.runtimeShell}
    exec ${lib.getExe pkgs.nodejs_25} "$out/lib/syncz/dist/main.js" "\$@"
    EOF
    chmod +x "$out/bin/syncz"

    runHook postInstall
  '';

  meta = {
    description = "Pure Nix TypeScript 7 hello world baseline for future repo sync tooling";
    homepage = "https://github.com/microsoft/typescript-go";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames platformPackages;
    mainProgram = "syncz";
  };
}
