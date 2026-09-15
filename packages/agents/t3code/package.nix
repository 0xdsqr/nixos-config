{
  t3code,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_11,
  rustPlatform,
}:
let
  version = "0.0.40";
  hash = "sha256-J8kXpfMfm03/DDAiWXJuANwUNDshhiUn7Lf9tV42Xfw=";
  pnpmDepsHash = "sha256-+UsoURSM4VP+CgF1fWROBEB85EuH+iJJM/xDPFigCKk=";
  cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";

  src = fetchFromGitHub {
    owner = "pingdotgg";
    repo = "t3code";
    tag = "v${version}";
    inherit hash;
  };

  unwrapped = t3code.unwrapped.overrideAttrs (
    final: _: {
      inherit version src;
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
