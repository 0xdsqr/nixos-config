{
  lib,
  stdenv,
  t3code,
  fetchFromGitHub,
  fetchPnpmDeps,
  libsecret,
  pkg-config,
  pnpm_11,
  rustPlatform,
}:
let
  version = "0.0.45";
  hash = "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=";
  pnpmDepsHash = "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=";
  cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";

  src = fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    inherit hash;
  };

  unwrapped = t3code.unwrapped.overrideAttrs (
    final: prev: {
      inherit version src;
      # The desktop build compiles a libsecret helper (native/browser-secret) on Linux.
      nativeBuildInputs = prev.nativeBuildInputs ++ lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
      buildInputs = (prev.buildInputs or [ ]) ++ lib.optionals stdenv.hostPlatform.isLinux [ libsecret ];
      pnpmDeps = fetchPnpmDeps {
        pnpm = pnpm_11;
        inherit (final)
          pname
          version
          src
          pnpmWorkspaces
          ;
        fetcherVersion = 4;
        hash = pnpmDepsHash;
      };
    }
  );

  resourceMonitor = t3code.resourceMonitor.overrideAttrs (_: {
    inherit version src;
    cargoDeps = rustPlatform.fetchCargoVendor {
      pname = "t3code-resource-monitor";
      inherit version src;
      sourceRoot = "${src.name}/native/resource-monitor";
      hash = cargoHash;
    };
  });
in
t3code.override {
  t3code-unwrapped = unwrapped;
  t3code-resource-monitor = resourceMonitor;
  enableCodex = false;
}
