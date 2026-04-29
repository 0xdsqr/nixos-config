{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.harpoon;
  type = "lua";
  config = /* lua */ ''
    require('harpoon').setup({
      global_settings = {
        save_on_toggle = true,
        save_on_change = true,
        mark_branch = true,
      },
    })

    vim.keymap.set('n', '<leader>ha', function()
      require('harpoon.mark').add_file()
    end, { desc = "Harpoon add file" })
    vim.keymap.set('n', '<leader>hh', function()
      require('harpoon.ui').toggle_quick_menu()
    end, { desc = "Harpoon menu" })
    vim.keymap.set('n', '<leader>1', function()
      require('harpoon.ui').nav_file(1)
    end, { desc = "Harpoon file 1" })
    vim.keymap.set('n', '<leader>2', function()
      require('harpoon.ui').nav_file(2)
    end, { desc = "Harpoon file 2" })
    vim.keymap.set('n', '<leader>3', function()
      require('harpoon.ui').nav_file(3)
    end, { desc = "Harpoon file 3" })
    vim.keymap.set('n', '<leader>4', function()
      require('harpoon.ui').nav_file(4)
    end, { desc = "Harpoon file 4" })
  '';
}
