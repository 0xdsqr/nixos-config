{
  bash,
  lib,
  stdenvNoCC,
  version ? "0.1.0-dev",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mgmt";
  inherit version;

  src = ./main.nu;
  dontFixup = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/libexec/mgmt

    substitute ${./cli.nu} $out/libexec/mgmt/cli.nu \
      --subst-var-by version ${version}
    install -m 0555 ${./main.nu} $out/libexec/mgmt/main.nu
    install -m 0555 ${./logger.nu} $out/libexec/mgmt/logger.nu
    install -m 0555 ${./mod.nu} $out/libexec/mgmt/mod.nu

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
  '';

  passthru = {
    modulePath = "${finalAttrs.finalPackage}/libexec/mgmt/mod.nu";
    mainPath = "${finalAttrs.finalPackage}/libexec/mgmt/main.nu";
    loggerPath = "${finalAttrs.finalPackage}/libexec/mgmt/logger.nu";
  };

  meta = {
    description = "Local management CLI for this nixos-config repository";
    longDescription = ''
      mgmt is a small Nushell-first management CLI for this nixos-config repository.

      Use the packaged executable as `mgmt`, or import the packaged Nushell module from
      `${finalAttrs.finalPackage}/libexec/mgmt/mod.nu` if you want to reuse the public
      commands from another Nu environment.
    '';
    mainProgram = "mgmt";
    platforms = lib.platforms.unix;
  };
})
