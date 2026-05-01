{
  flake.homeModules.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.opencode;
    in
    {
      options.dsqr.home.opencode = {
        enable = mkEnableOption "OpenCode CLI and config" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.opencode;
          description = "OpenCode package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        xdg.configFile."opencode/README.md".text =
          "Drop OpenCode config and helpers here when you want them managed declaratively.\n";

        xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          autoupdate = false;
        };
      };
    };
}
