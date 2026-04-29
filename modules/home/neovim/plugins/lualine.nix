{ lib, pkgs }:
let
  inherit (lib.lists) singleton;
in
singleton {
  plugin = pkgs.vimPlugins.lualine-nvim;
  type = "lua";
  config = /* lua */ ''
    require('lualine').setup({
      options = {
        theme = 'tokyonight',
        component_separators = '|',
        section_separators = "",
      },
      sections = {
        lualine_c = {
          { 'filename', path = 1 }
        },
      },
    })
  '';
}
