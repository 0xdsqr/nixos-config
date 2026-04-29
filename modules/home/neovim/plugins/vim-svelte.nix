{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton pkgs.vimPlugins.vim-svelte
