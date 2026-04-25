{
  flake.homeModules.hammerspoon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/hammerspoon";

      xdg.configFile."hammerspoon/init.lua" = {
        text = ''
          local darwin_wm_path = hs.configdir .. "/darwin-wm.lua"

          local ok, darwin_wm = pcall(dofile, darwin_wm_path)

          if ok and type(darwin_wm) == "table" and type(darwin_wm.setup) == "function" then
            darwin_wm.setup()
            hs.alert.show("Hammerspoon WM loaded")
          else
            hs.alert.show("Failed to load darwin-wm.lua")
          end
        '';
      };
    };
}
