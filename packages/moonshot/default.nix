{ lib, go, stdenv }:
let
  pname = "moonshot";
  version = "0.0.0-sandbox.0";

  # Build from the local nested module first so we can iterate without
  # pinning a Git revision yet.
  src = ./.;

  nativeBuildInputs = [ go ];
  doCheck = true;

  description = "Moonshot CLI";
  mainProgram = "moonshot";
in
stdenv.mkDerivation {
  inherit
    pname
    version
    src
    nativeBuildInputs
    doCheck
    ;

  # We leave unpackPhase at the default: unpack the source tree into the build dir.
  # We skip configurePhase entirely because this small Go CLI has nothing to configure.
  # We keep fixupPhase at the default so Nix can do its normal post-install cleanup.
  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR"
    export GOCACHE="$TMPDIR/go-build"
    export GOMODCACHE="$TMPDIR/go-mod"

    go build \
      -ldflags="-X github.com/0xdsqr/moonshot/internal/version.Value=${version}" \
      -o moonshot \
      ./cmd/moonshot

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    export HOME="$TMPDIR"
    export GOCACHE="$TMPDIR/go-build"
    export GOMODCACHE="$TMPDIR/go-mod"

    go test ./...

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 moonshot "$out/bin/moonshot"

    runHook postInstall
  '';

  meta = with lib; {
    inherit description mainProgram;
    platforms = platforms.all;
  };
}
