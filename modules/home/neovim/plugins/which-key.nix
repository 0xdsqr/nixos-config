{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.which-key-nvim;
  type = "lua";
  config = /* lua */ ''
    require('which-key').setup({})
  '';
}
