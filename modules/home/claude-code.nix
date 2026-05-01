{
  flake.homeModules."claude-code" =
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

      cfg = config.dsqr.home.claudeCode;
    in
    {
      options.dsqr.home.claudeCode = {
        enable = mkEnableOption "Claude Code CLI and config";

        package = mkOption {
          type = package;
          default = pkgs.claude-code;
          description = "Claude Code package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";

        xdg.configFile."claude-code/README.md".text =
          "Drop Claude Code config and helpers here when you want them managed declaratively.\n";

        xdg.configFile."claude-code/settings.json".text = builtins.toJSON {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        };
      };
    };
}
