inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.eevee;
in
{
  programs.neovim = {
    enable = true;
    # Use nightly package from the input
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      {
        plugin = tokyonight-nvim;
        config = "colorscheme tokyonight";
      }
      telescope-nvim
      plenary-nvim
    ];

    extraLuaConfig = ''
      -- Set leader key
      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

      -- Line numbers plus relative numbers
      vim.opt.nu = true
      vim.opt.relativenumber = true

      -- Indenting
      vim.opt.tabstop = 4
      vim.opt.softtabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.expandtab = true

      -- Line Wraps
      vim.opt.smartindent = true
      vim.opt.wrap = false

      -- No swap/backup files, use undodir instead
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
      vim.opt.undofile = true

      -- Search settings
      vim.opt.hlsearch = false
      vim.opt.incsearch = true

      -- Scrolling
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.isfname:append("@-@")

      -- Misc
      vim.opt.updatetime = 50
      vim.opt.termguicolors = true
      vim.guicursor = ""
      vim.opt.colorcolumn = "80"

      -- Telescope keymaps
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', '<leader>pg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep >") })
      end)
    '';
  };
}
