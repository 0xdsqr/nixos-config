{
  bash,
  lib,
  stdenvNoCC,
  version ? "0.1.0-dev",
}:
let
  source = lib.cleanSource ./.;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mgmt";
  inherit version;

  src = source;
  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/mgmt $out/share/mgmt

    substitute $src/cli.nu $out/libexec/mgmt/cli.nu \
      --subst-var-by version ${finalAttrs.version}
    install -m 0555 $src/main.nu $out/libexec/mgmt/main.nu
    install -m 0555 $src/logger.nu $out/libexec/mgmt/logger.nu
    install -m 0555 $src/mod.nu $out/libexec/mgmt/mod.nu
    cp -R $src/templates $out/share/mgmt/templates

    cat > $out/bin/mgmt <<EOF
    #!${lib.getExe bash}
    set -euo pipefail

    if ! command -v nu >/dev/null 2>&1; then
      echo "mgmt: missing 'nu' in PATH" >&2
      echo "mgmt: this repo CLI currently expects Nushell to be installed locally" >&2
      exit 1
    fi

    exec nu --no-config-file "$out/libexec/mgmt/main.nu" "\$@"
    EOF

    chmod +x $out/bin/mgmt

    runHook postInstall
  '';

  meta = {
    description = "Local management CLI for this nixos-config repository";
    mainProgram = "mgmt";
    platforms = lib.platforms.unix;
  };
})
