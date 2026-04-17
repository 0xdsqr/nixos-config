{ lib, go, stdenv }:

stdenv.mkDerivation rec {
  pname = "moonshot";
  version = "0.0.0-sandbox.0";

  # Build from the local nested module first so we can iterate without
  # pinning a Git revision yet.
  src = ./.;

  # Go is a build-time tool, so it belongs in nativeBuildInputs.
  nativeBuildInputs = [ go ];

  doCheck = true;

  # We keep the default unpack/fixup phases and only customize the parts
  # specific to this small Go CLI: build, test, and install.
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
    description = "Moonshot CLI";
    mainProgram = "moonshot";
    platforms = platforms.all;
  };
}
