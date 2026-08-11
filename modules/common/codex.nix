{
  flake.commonModules.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) recursiveUpdate;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;

      cfg = config.dsqr.codex;
      tomlFormat = pkgs.formats.toml { };
      defaultSettings = {
        model = "gpt-5.6-sol";
        model_reasoning_effort = "high";
        service_tier = "fast";
        approvals_reviewer = "auto_review";

        features = {
          child_agents_md = true;
          hooks = true;
        };
      };
    in
    {
      options.dsqr.codex = {
        enable = mkEnableOption "system-wide Codex defaults";

        settings = mkOption {
          inherit (tomlFormat) type;
          default = { };
          apply = recursiveUpdate defaultSettings;
          description = "Settings written to Codex's read-only system configuration layer.";
        };
      };

      config = mkIf cfg.enable {
        # Keep declarative defaults in Codex's read-only system layer. The
        # higher-precedence user config remains writable for workspace trust,
        # TUI choices, skill state, and other interactive configuration.
        environment.etc."codex/config.toml".source = tomlFormat.generate "codex-system-config" cfg.settings;
      };
    };
}
