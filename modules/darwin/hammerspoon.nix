{
  flake.darwinModules.hammerspoon = {
    system.defaults.CustomSystemPreferences."org.hammerspoon.Hammerspoon".MJConfigFile = "~/.config/hammerspoon/init.lua";

    homebrew.casks = [ "hammerspoon" ];
  };
}
