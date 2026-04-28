{ inputs, ... }:
{
  flake.homeModules.codexbar =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.nix-steipete-tools.homeManagerModules.codexbar ];

      programs.codexbar = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        launchd.enable = true;
      };
    };
}
