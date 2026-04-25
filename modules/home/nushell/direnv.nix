{
  flake.homeModules.direnv =
    { pkgs, ... }:
    let
      # direnv's upstream shell test suite can hang during first-time Darwin rebuilds,
      # so we skip checks here to keep workstation bootstrap reliable.
      direnvPackage = pkgs.direnv.overrideAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    in
    {
      home.packages = [ pkgs.nix-direnv ];

      programs.direnv = {
        enable = true;
        package = direnvPackage;
        silent = false;
        nix-direnv.enable = true;
        enableNushellIntegration = true;
        config = { };
      };
    };
}
