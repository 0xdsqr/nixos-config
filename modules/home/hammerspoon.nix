{
  flake.homeModules.hammerspoon =
    { lib, osConfig, ... }:
    {
      xdg.configFile."hammerspoon/init.lua" = lib.mkIf osConfig.nixpkgs.hostPlatform.isDarwin {
        text = /* lua */ ''
          PaperWM = hs.loadSpoon("PaperWM")
          Swipe = hs.loadSpoon("Swipe")
        '';
      };
    };
}
