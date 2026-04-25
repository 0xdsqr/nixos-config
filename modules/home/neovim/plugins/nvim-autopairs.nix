{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.nvim-autopairs;
    type = "lua";
    config = ''
      require('nvim-autopairs').setup({})
    '';
  }
]
