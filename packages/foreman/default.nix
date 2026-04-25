{
  bash,
  lib,
  stdenvNoCC,
  version ? "0.1.0-dev",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "foreman";
  inherit version;

  src = ./main.nu;
  dontFixup = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/libexec/foreman

    substitute ${./cli.nu} $out/libexec/foreman/cli.nu \
      --subst-var-by version ${version}
    install -m 0555 ${./main.nu} $out/libexec/foreman/main.nu
    install -m 0555 ${./logger.nu} $out/libexec/foreman/logger.nu
    install -m 0555 ${./mod.nu} $out/libexec/foreman/mod.nu

    cat > $out/bin/foreman <<EOF
    #!${lib.getExe bash}
    set -euo pipefail

    if ! command -v nu >/dev/null 2>&1; then
      echo "foreman: missing 'nu' in PATH" >&2
      echo "foreman: this repo CLI currently expects Nushell to be installed locally" >&2
      exit 1
    fi

    exec nu --no-config-file "$out/libexec/foreman/main.nu" "\$@"
    EOF

    chmod +x $out/bin/foreman
  '';

  passthru = {
    modulePath = "${finalAttrs.finalPackage}/libexec/foreman/mod.nu";
    mainPath = "${finalAttrs.finalPackage}/libexec/foreman/main.nu";
    loggerPath = "${finalAttrs.finalPackage}/libexec/foreman/logger.nu";
  };

  meta = {
    description = "Local CLI for this nixos-config repository";
    longDescription = ''
      foreman is a small Nushell-first CLI for this nixos-config repository.

      Use the packaged executable as `foreman`, or import the packaged Nushell module from
      `${finalAttrs.finalPackage}/libexec/foreman/mod.nu` if you want to reuse the public
      commands from another Nu environment.
    '';
    mainProgram = "foreman";
    platforms = lib.platforms.unix;
  };
})
