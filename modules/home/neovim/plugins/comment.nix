{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.comment-nvim;
  type = "lua";
  config = /* lua */ ''
    require('Comment').setup()
  '';
}
