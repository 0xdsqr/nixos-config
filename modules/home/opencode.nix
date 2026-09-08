{
  flake.homeModules.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkDefault mkIf;
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
        programs.opencode = {
          enable = true;
          inherit (cfg) package;
          settings.autoupdate = mkDefault false;
        };

        xdg.configFile."opencode/README.md".text =
          "Drop OpenCode config and helpers here when you want them managed declaratively.\n";

      };
    };
}
