{
  flake.homeModules.codex =
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

      cfg = config.dsqr.home.codex;
      codexHome = "${config.xdg.configHome}/codex";
    in
    {
      options.dsqr.home.codex = {
        enable = mkEnableOption "Codex CLI tooling and config" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.codex;
          description = "Codex package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        home.sessionVariables.CODEX_HOME = codexHome;

        xdg.configFile."codex/config.toml" = {
          text = /* toml */ ''
            [features]
            child_agents_md = true
          '';
        };

        xdg.configFile."codex/plugins/README.md" = {
          text = "Drop Codex plugins here when you want them managed declaratively.\n";
        };

        xdg.configFile."codex/agents/README.md" = {
          text = "Drop Codex agent presets here when you want them managed declaratively.\n";
        };
      };
    };
}
