{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.indent-blankline-nvim;
  type = "lua";
  config = /* lua */ ''
    require('ibl').setup({
      indent = { char = "│" },
      scope = { enabled = true },
    })
  '';
}
