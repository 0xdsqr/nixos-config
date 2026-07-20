{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.which-key-nvim;
  type = "lua";
  config = /* lua */ ''
    local which_key = require('which-key')
    which_key.setup({})
    which_key.add({
      { '<leader>b', group = 'buffers' },
      { '<leader>h', group = 'git hunks / harpoon' },
      { '<leader>n', group = 'nix / project' },
      { '<leader>p', group = 'project search' },
      { '<leader>s', group = 'symbols' },
      { '<leader>t', group = 'file tree' },
    })
  '';
}
