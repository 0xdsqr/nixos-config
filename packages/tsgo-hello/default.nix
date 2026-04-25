{
  lib,
  runtimeShell,
  stdenvNoCC,
}:
let
  name = "list-repo-files";
in
stdenvNoCC.mkDerivation {
  pname = name;
  version = "0.1.0";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = /* bash */ ''
    runHook preInstall

    mkdir -p "$out/bin"

    cat > "$out/bin/${name}" <<EOF
    #!${runtimeShell}
    echo "Hello from ${name}"
    EOF

    chmod 0755 "$out/bin/${name}"

    runHook postInstall
  '';

  meta = {
    description = "Minimal Nix scaffold";
    license = lib.licenses.mit;
    mainProgram = name;
    platforms = lib.platforms.all;
  };
}
