{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.blink-cmp;
  type = "lua";
  config = /* lua */ ''
    require('blink.cmp').setup({
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      signature = {
        enabled = true,
      },
    })
  '';
}
