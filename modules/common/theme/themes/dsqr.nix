{ pkgs, mkTheme }:
mkTheme {
  name = "dsqr";
  isDark = true;
  margin = 8;
  padding = 8;
  cornerRadius = 10;

  wallpaper = {
    darwin = null;
    linux = null;
    mode = "fill";
  };

  colors = {
    bg0 = "#1f1b18";
    bg1 = "#2a241f";
    bg2 = "#4a3a2a";
    fg0 = "#f7efe5";
    fg1 = "#e7d9c8";
    fg2 = "#6f6155";
    border = "#5a4633";
    split = "#161311";

    yellow = "#f0c674";
    yellowSoft = "#d7b16d";
    yellowBright = "#e7c784";

    red = "#c97b63";
    redSoft = "#df8f78";

    green = "#9aad6d";
    greenSoft = "#b6c987";

    blue = "#7ea1c5";
    blueSoft = "#98b7d8";

    purple = "#b48ead";
    purpleSoft = "#c7a0c0";

    aqua = "#7eb5a6";
    aquaSoft = "#99cbbc";
  };

  font = {
    sans = {
      name = "Lexend";
      package = pkgs.lexend;
    };

    mono = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };

    size = {
      normal = 16;
      large = 18;
      big = 20;
    };
  };
}
