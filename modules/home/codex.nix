{
  flake.homeModules.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.codex;
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
        programs.codex = {
          enable = true;
          inherit (cfg) package;
          settings.features.child_agents_md = true;
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
