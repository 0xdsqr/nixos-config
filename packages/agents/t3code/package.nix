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
  spdx-license-list-data,
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
      # The third-party-licenses plugin downloads SPDX texts during the build, which
      # the sandbox blocks; seed its cache from nixpkgs for whatever version it pins.
      preBuild = ''
        spdxVersion=$(sed -n 's/^const SPDX_LICENSE_LIST_VERSION = "\(.*\)";$/\1/p' scripts/lib/third-party-licenses.ts)
        mkdir -p ".generated/third-party-licenses/spdx/$spdxVersion"
        cp ${spdx-license-list-data.json}/json/details/*.json ".generated/third-party-licenses/spdx/$spdxVersion/"
      ''
      + prev.preBuild;
      # pnpmBuildHook's recursive `pnpm run --filter=...` collapses vp's task output,
      # hiding build errors; run the same root script directly so it streams.
      buildPhase = ''
        runHook preBuild
        pnpm run build:desktop
        runHook postBuild
      '';
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
