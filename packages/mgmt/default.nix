{
  bash,
  lib,
  stdenvNoCC,
  version ? "0.1.0-dev",
}:
stdenvNoCC.mkDerivation {
  pname = "mgmt";
  inherit version;

  src = ./main.nu;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/libexec
    substitute ${./main.nu} $out/libexec/mgmt.nu \
      --subst-var-by version ${version}
    cat > $out/bin/mgmt <<EOF
    #!${lib.getExe bash}
    set -euo pipefail

    if ! command -v nu >/dev/null 2>&1; then
      echo "mgmt: missing 'nu' in PATH" >&2
      echo "mgmt: this repo CLI currently expects Nushell to be installed locally" >&2
      exit 1
    fi

    exec nu "$out/libexec/mgmt.nu" "\$@"
    EOF
    chmod +x $out/bin/mgmt $out/libexec/mgmt.nu
  '';

  meta = {
    description = "Local management CLI for this nixos-config repository";
    mainProgram = "mgmt";
    platforms = lib.platforms.unix;
  };
}
