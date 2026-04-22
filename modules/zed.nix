{
  flake.homeModules.zed =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkIf;
    in
    mkIf pkgs.stdenv.isDarwin {
      programs.zed-editor = {
        enable = true;
        package = null;

        userSettings = {
          base_keymap = "VSCode";
          load_direnv = "shell_hook";
          ui_font_size = 16;
          buffer_font_size = 15;
          vim_mode = false;

          telemetry = {
            metrics = false;
            diagnostics = false;
          };
        };

        extensions = [ "nix" ];
      };
    };
  flake.darwinModules.zed =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      inherit (config.dsqr.darwin) devbox;
    in
    mkIf devbox.enable { homebrew.casks = [ "zed" ]; };
}
