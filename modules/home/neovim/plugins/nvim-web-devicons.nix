{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton pkgs.vimPlugins.nvim-web-devicons
