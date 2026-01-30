{
  lib,
  exclude_casks ? [ ],
}:
let
  discretionaryCasks = [
    "ghostty"
    "spotify"
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
    "tailscale-app"
    "tigervnc-viewer"
    "microsoft-remote-desktop"
    "remoteviewer"
  ];

  filtered = lib.lists.subtractLists exclude_casks discretionaryCasks;
in
{
  casks = filtered;
}
