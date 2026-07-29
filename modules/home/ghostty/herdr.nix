{
  flake.homeModules.ghostty-herdr =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrByPath recursiveUpdate;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) attrs package;

      cfg = config.dsqr.home.desktop.ghostty.herdr;
      nuEnabled = attrByPath [ "dsqr" "home" "nu" "enable" ] false config;
      colors = config.dsqr.theme.colors;
      tomlFormat = pkgs.formats.toml { };

      defaultSettings = {
        onboarding = false;

        theme = {
          name = "terminal";
          custom = {
            accent = colors.magentaBright;
            panel_bg = colors.backgroundDark;
            surface0 = colors.backgroundSoft;
            surface1 = colors.selection;
            surface_dim = colors.background;
            overlay0 = colors.divider;
            overlay1 = colors.inactive;
            text = colors.foreground;
            subtext0 = colors.inactive;
            mauve = colors.magentaBright;
            green = colors.greenBright;
            yellow = colors.yellowBright;
            red = colors.redBright;
            blue = colors.blueBright;
            teal = colors.cyanBright;
            peach = colors.yellow;
          };
        };

        terminal.default_shell = "${config.home.profileDirectory}/bin/nu";

        keys = {
          prefix = "ctrl+space";
          settings = "prefix+shift+s";
          workspace_picker = [
            "prefix+s"
            "prefix+w"
          ];
          detach = [
            "prefix+d"
            "prefix+q"
          ];
        };

        ui = {
          accent = colors.magentaBright;
          sidebar_start_collapsed = false;
        };
      };
    in
    {
      options.dsqr.home.desktop.ghostty.herdr = {
        enable = mkEnableOption "Herdr persistent terminal workspaces";

        package = mkOption {
          type = package;
          default = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
          description = "Herdr package to install.";
        };

        settings = mkOption {
          type = attrs;
          default = { };
          description = "Herdr settings recursively merged over the focused dsqr defaults.";
        };
      };

      config = mkIf cfg.enable {
        assertions = singleton {
          assertion = nuEnabled;
          message = "dsqr.home.desktop.ghostty.herdr requires dsqr.home.nu so new panes have the configured Nushell environment.";
        };

        home.packages = singleton cfg.package;

        xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" (
          recursiveUpdate defaultSettings cfg.settings
        );
      };
    };
}
