{
  flake.homeModules."window-manager" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.desktop.windowManager;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      options.dsqr.home.desktop.windowManager.enable = mkEnableOption "Home desktop window manager support";

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = isDarwin;
            message = "dsqr.home.desktop.windowManager requires Darwin.";
          }
        ];

        xdg.configFile."hammerspoon/Spoons/PaperWM.spoon" = mkIf isDarwin {
          source = pkgs.fetchFromGitHub {
            owner = "mogenson";
            repo = "PaperWM.spoon";
            rev = "88aa02ad9002d1b5697aeaf9fb27cdb5cedc4964";
            hash = "sha256-c6ltYZKLjZXXin8UaURY0xIrdFvA06aKxC5oty2FCdY=";
          };
        };

        xdg.configFile."hammerspoon/Spoons/Swipe.spoon" = mkIf isDarwin {
          source = pkgs.fetchFromGitHub {
            owner = "mogenson";
            repo = "Swipe.spoon";
            rev = "c56520507d98e663ae0e1228e41cac690557d4aa";
            hash = "sha256-G0kuCrG6lz4R+LdAqNWiMXneF09pLI+xKCiagryBb5k=";
          };
        };
      };
    };
}
