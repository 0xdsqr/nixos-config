{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dsqrDevbox;
in
{
  programs.neovim = {
    enable = true;
    # Use nightly package from the input
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = tokyonight-nvim;
        config = "colorscheme tokyonight";
      }
    ];
  };
}
