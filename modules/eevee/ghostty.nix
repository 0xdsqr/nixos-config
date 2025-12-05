{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      # Window settings
      window-padding-x = 10;
      window-padding-y = 10;

      # Font
      font-family = "JetBrains Mono";
      font-size = 12;

      # Basic keybinds
      keybind = [
        "ctrl+k=reset"
      ];
    };
  };
}
