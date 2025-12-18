{
  lib,
  stdenv,
  bun,
}:
stdenv.mkDerivation {
  pname = "sysdsqr";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    # Compile TypeScript to single binary executable
    bun build --compile --minify --sourcemap ./index.ts --outfile sysdsqr
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp sysdsqr $out/bin/sysdsqr
    chmod +x $out/bin/sysdsqr
  '';

  meta = with lib; {
    description = "System admin CLI for dsqr homelab";
    homepage = "https://github.com/yourusername/nixos-config";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
