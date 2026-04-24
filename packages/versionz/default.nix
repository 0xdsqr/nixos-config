{
  bash,
  lib,
  packageVersion ? "0.1.0-dev",
  stdenvNoCC,
  version ? "dev",
}:
stdenvNoCC.mkDerivation {
  pname = "versionz";
  version = packageVersion;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/versionz <<EOF
    #!${lib.getExe bash}
    set -euo pipefail
    echo "${version}"
    EOF

    chmod +x $out/bin/versionz
  '';

  meta = {
    description = "Minimal version printer for this nixos-config flake";
    mainProgram = "versionz";
    platforms = lib.platforms.unix;
  };
}
