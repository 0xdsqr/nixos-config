{
  lib,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
}:
let
  version = "0.42.1";
in
stdenvNoCC.mkDerivation {
  pname = "codexbar";
  inherit version;

  src = fetchzip {
    url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBar-macos-universal-${version}.zip";
    hash = "sha256-sVqyYISVswRUpGJtwqTV9arrmuVtcYC6cqhl02D3UJM=";
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

  nativeBuildInputs = [ makeWrapper ];

  meta = {
    description = "Tiny macOS menu bar app for AI coding-provider usage limits";
    homepage = "https://github.com/steipete/CodexBar";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.darwin;
  };
}
