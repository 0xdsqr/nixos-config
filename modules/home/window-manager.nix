{
  flake.homeModules."window-manager" =
    { lib, pkgs, ... }:
    {
      xdg.configFile."hammerspoon/Spoons/PaperWM.spoon" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = pkgs.fetchFromGitHub {
          owner = "mogenson";
          repo = "PaperWM.spoon";
          rev = "88aa02ad9002d1b5697aeaf9fb27cdb5cedc4964";
          hash = "sha256-c6ltYZKLjZXXin8UaURY0xIrdFvA06aKxC5oty2FCdY=";
        };
      };

      xdg.configFile."hammerspoon/Spoons/Swipe.spoon" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = pkgs.fetchFromGitHub {
          owner = "mogenson";
          repo = "Swipe.spoon";
          rev = "c56520507d98e663ae0e1228e41cac690557d4aa";
          hash = "sha256-G0kuCrG6lz4R+LdAqNWiMXneF09pLI+xKCiagryBb5k=";
        };
      };
    };
}
