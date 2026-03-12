{
  lib,
  exclude_casks ? [],
}: let
  discretionaryCasks = [
    "ghostty"
    "spotify"
    "zoom"
    "1password"
    "cleanshot"
    "discord"
    "raycast"
    "obsidian"
    "vlc"
    "signal"
    "typora"
    "dropbox"
    "chromium"
    "helium-browser"
    "tailscale-app"
    "microsoft-remote-desktop"
    "remoteviewer"
  ];

  filtered = lib.lists.subtractLists exclude_casks discretionaryCasks;
in {
  casks = filtered;
}
