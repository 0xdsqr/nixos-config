{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
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
}
