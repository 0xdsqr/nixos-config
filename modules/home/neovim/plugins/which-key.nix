{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.which-key-nvim;
    type = "lua";
    config = ''
      require('which-key').setup({})
    '';
  }
]
