{
  flake.darwinModules.chatgpt =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;
      cfg = config.dsqr.darwin.desktop.chatgpt;
    in
    {
      options.dsqr.darwin.desktop.chatgpt = {
        enable = mkEnableOption "ChatGPT desktop app with Codex";

        package = mkOption {
          type = str;
          default = "chatgpt";
          description = "Homebrew cask to install for the ChatGPT desktop app.";
        };
      };

      config = mkIf cfg.enable { homebrew.casks = singleton cfg.package; };
    };
}
