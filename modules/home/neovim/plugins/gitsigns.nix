{ pkgs }:
[
  {
    plugin = pkgs.vimPlugins.gitsigns-nvim;
    type = "lua";
    config = ''
      require('gitsigns').setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local opts = { buffer = bufnr }

          vim.keymap.set('n', ']c', gs.next_hunk, opts)
          vim.keymap.set('n', '[c', gs.prev_hunk, opts)
          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts)
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts)
          vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts)
          vim.keymap.set('n', '<leader>hb', gs.blame_line, opts)
        end,
      })
    '';
  }
]
