{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.blink-cmp;
    type = "lua";
    config = ''
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
]
