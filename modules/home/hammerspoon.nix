{
  flake.homeModules.hammerspoon =
    { lib, pkgs, ... }:
    {
      xdg.configFile."hammerspoon/init.lua" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        text = ''
          local ok, darwin_wm = pcall(require, "darwin-wm")

          if ok and type(darwin_wm.setup) == "function" then
            darwin_wm.setup()
          end
        '';
      };
    };
}
