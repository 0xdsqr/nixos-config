{
  flake.homeModules."darwin-wm" =
    { lib, pkgs, ... }:
    {
      xdg.configFile."hammerspoon/darwin-wm.lua" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        text = ''
          local M = {}

          function M.setup()
            -- Add Hammerspoon window-management bindings here.
            -- Good future candidates:
            --   paper-style window focus
            --   workspace hotkeys
            --   app launchers
          end

          return M
        '';
      };
    };
}
