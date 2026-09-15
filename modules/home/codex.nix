{
  flake.homeModules.codex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.modules) mkDefault mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        attrsOf
        nullOr
        package
        str
        ;

      cfg = config.dsqr.home.codex;
      codexHome = config.home.sessionVariables.CODEX_HOME or "${config.home.homeDirectory}/.codex";
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

        desktop.keybindings = mkOption {
          type = attrsOf (nullOr str);
          default = { };
          example = {
            openAvatarOverlay = "Ctrl+Alt+Command+Space";
          };
          description = ''
            Codex desktop command shortcuts managed in CODEX_HOME/keybindings.json.
            Override individual commands here; null disables a command's shortcut.
            Unlisted commands retain Codex's defaults. While this file is managed,
            change shortcuts in Nix rather than the app's settings.
          '';
        };
      };

      config = mkIf cfg.enable {
        dsqr.home.codex.desktop.keybindings = mkIf pkgs.stdenv.isDarwin {
          openAvatarOverlay = mkDefault "Ctrl+Alt+Command+Space";
        };

        programs.codex = {
          enable = true;
          inherit (cfg) package;
        };

        home.file."${codexHome}/keybindings.json" = mkIf (cfg.desktop.keybindings != { }) {
          text = builtins.toJSON (mapAttrsToList (command: key: { inherit command key; }) cfg.desktop.keybindings);
        };

        xdg.configFile = {
          "codex/plugins/README.md" = {
            text = "Drop Codex plugins here when you want them managed declaratively.\n";
          };

          "codex/agents/README.md" = {
            text = "Drop Codex agent presets here when you want them managed declaratively.\n";
          };
        };
      };
    };
}
