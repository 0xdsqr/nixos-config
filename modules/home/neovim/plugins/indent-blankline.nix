{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.indent-blankline-nvim;
    type = "lua";
    config = ''
      require('ibl').setup({
        indent = { char = "│" },
        scope = { enabled = true },
      })
    '';
  }
]
