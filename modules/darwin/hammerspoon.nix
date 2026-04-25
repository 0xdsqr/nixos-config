{
  flake.darwinModules.hammerspoon = _: {
    homebrew.casks = [ "hammerspoon" ];

    system.defaults.CustomSystemPreferences."org.hammerspoon.Hammerspoon".MJConfigFile = "~/.config/hammerspoon/init.lua";
  };
}
