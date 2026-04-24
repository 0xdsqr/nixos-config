{
  flake.homeModules.direnv =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.direnv pkgs.nix-direnv ];

      programs.direnv = {
        enable = true;
        silent = false;

        nix-direnv.enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;

        config = {
          # whitelist = {
          #   prefix = [ "$HOME/workspace/code" ];
          #   exact = [ "$HOME/.envrc" ];
          # };
        };
      };
    };
}
