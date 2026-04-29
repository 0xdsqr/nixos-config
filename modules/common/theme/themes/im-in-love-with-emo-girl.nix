{ pkgs, mkTheme }:
mkTheme {
  name = "im-in-love-with-emo-girl";
  isDark = true;
  margin = 8;
  padding = 8;
  cornerRadius = 14;

  wallpaper = {
    darwin = ../wallpapers/im-in-love-with-emo-girl.jpg;
    linux = ../wallpapers/im-in-love-with-emo-girl.jpg;
    mode = "fill";
  };

  colors = {
    bg0 = "#17131f";
    bg1 = "#211a2b";
    bg2 = "#342748";
    fg0 = "#f2eaff";
    fg1 = "#dbcdf6";
    fg2 = "#8e82a7";
    border = "#53406f";
    split = "#110d17";

    yellow = "#c9a7ff";
    yellowSoft = "#b892ff";
    yellowBright = "#d7bcff";

    red = "#e48fb6";
    redSoft = "#f2a8c9";

    green = "#8fd5c8";
    greenSoft = "#a6e8db";

    blue = "#7aa2f7";
    blueSoft = "#93b4ff";

    purple = "#bb9af7";
    purpleSoft = "#ceb3ff";

    aqua = "#7dcfff";
    aquaSoft = "#9ad9ff";
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
