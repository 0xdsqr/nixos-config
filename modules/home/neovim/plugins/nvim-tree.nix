{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.nvim-tree-lua;
    type = "lua";
    config = ''
      require('nvim-tree').setup({
        view = { width = 35 },
        filters = { dotfiles = false },
        sync_root_with_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
      })
      vim.keymap.set('n', '<leader>tt', ':NvimTreeToggle<CR>', { desc = "Toggle file tree" })
      vim.keymap.set('n', '<leader>tf', ':NvimTreeFindFile<CR>', { desc = "Find file in tree" })
    '';
  }
]
