{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.nvim-surround;
  type = "lua";
  config = /* lua */ ''
    require('nvim-surround').setup({})
  '';
}
