{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.nvim-autopairs;
  type = "lua";
  config = /* lua */ ''
    require('nvim-autopairs').setup({})
  '';
}
