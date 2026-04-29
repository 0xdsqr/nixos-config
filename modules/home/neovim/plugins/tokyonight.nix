{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.tokyonight-nvim;
  type = "lua";
  config = /* lua */ ''
    vim.cmd.colorscheme("tokyonight-night")
  '';
}
