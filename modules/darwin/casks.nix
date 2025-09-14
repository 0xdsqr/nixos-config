{
  lib,
  exclude_casks ? [ ],
}:
let
  discretionaryCasks = [
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
  ];

  filtered = lib.lists.subtractLists exclude_casks discretionaryCasks;
in
{
  casks = filtered;
}
