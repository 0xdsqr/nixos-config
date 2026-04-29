{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.telescope-nvim;
  type = "lua";
  config = /* lua */ ''
    local telescope = require('telescope')
    local builtin = require('telescope.builtin')

    telescope.setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
      },
    })
    telescope.load_extension('fzf')

    vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "Find files" })
    vim.keymap.set('n', '<leader>pg', builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = "Buffers" })
    vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = "Help tags" })
    vim.keymap.set('n', '<leader>ps', function()
      builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end, { desc = "Grep string" })
    vim.keymap.set('n', '<leader>pd', builtin.diagnostics, { desc = "Diagnostics" })
    vim.keymap.set('n', '<leader>ss', builtin.lsp_document_symbols, { desc = "Document symbols" })
    vim.keymap.set('n', '<leader>sS', builtin.lsp_dynamic_workspace_symbols, { desc = "Workspace symbols" })
  '';
}
