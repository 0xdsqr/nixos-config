{ pkgs, themeLib }:
{
  dsqr = import ./themes/dsqr.nix {
    inherit pkgs;
    inherit (themeLib) mkTheme;
  };

  "im-in-love-with-emo-girl" = import ./themes/im-in-love-with-emo-girl.nix {
    inherit pkgs;
    inherit (themeLib) mkTheme;
  };
}
