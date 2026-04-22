{
  flake.homeModules.direnv =
    { pkgs, ... }:
    {
      programs.direnv = {
        enable = true;
        enableNushellIntegration = pkgs.stdenv.isLinux;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
