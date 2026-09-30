{
  t3code,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_11,
  rustPlatform,
}:
let
  version = "0.0.44";
  hash = "sha256-cSkGa6b+WGbXJ+lbpJ3tfCibtvaj7DwWhn66UGiXlWk=";
  pnpmDepsHash = "sha256-xdS9+PqIDULKIu3+lQRMabA23D0dxCEME96NhFggWPY=";
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
