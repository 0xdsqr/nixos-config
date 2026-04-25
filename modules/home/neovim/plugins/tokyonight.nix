{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.tokyonight-nvim;
    type = "lua";
    config = ''
      vim.cmd.colorscheme("tokyonight-night")
    '';
  }
]
