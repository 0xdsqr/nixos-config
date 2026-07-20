{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.gitsigns-nvim;
  type = "lua";
  config = /* lua */ ''
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

        vim.keymap.set('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, vim.tbl_extend('force', opts, { desc = 'Next git hunk' }))
        vim.keymap.set('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, vim.tbl_extend('force', opts, { desc = 'Previous git hunk' }))
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts)
        vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts)
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts)
        vim.keymap.set('n', '<leader>hb', gs.blame_line, opts)
      end,
    })
  '';
}
