{ lib, ... }:
{
  flake.commonModules.codexbar-package = _: {
    nixpkgs.overlays = [
      (final: _: {
        codexbar = final.stdenvNoCC.mkDerivation rec {
          pname = "codexbar";
          version = "0.24";

          src = final.fetchzip {
            url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBar-${version}.zip";
            hash = "sha256-hoLwMoNqvOilfU6xvWE/6OZEEtcvOlSmiCNNpUlgtLI=";
            stripRoot = false;
          };

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/Applications" "$out/bin"
            cp -R "$src/CodexBar.app" "$out/Applications/"
            makeWrapper "$out/Applications/CodexBar.app/Contents/MacOS/CodexBar" "$out/bin/codexbar"

            runHook postInstall
          '';

          nativeBuildInputs = [ final.makeWrapper ];

          meta = {
            description = "Tiny macOS menu bar app for AI coding-provider usage limits";
            homepage = "https://github.com/steipete/CodexBar";
            license = lib.licenses.mit;
            mainProgram = "codexbar";
            platforms = lib.platforms.darwin;
          };
        };
      })
    ];
  };
}
