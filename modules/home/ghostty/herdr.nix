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
      inherit (lib.hm.nushell) toNushell;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        attrs
        attrsOf
        int
        listOf
        nullOr
        package
        str
        submodule
        ;

      cfg = config.dsqr.home.desktop.ghostty.herdr;
      nuEnabled = attrByPath [ "dsqr" "home" "nu" "enable" ] false config;
      colors = config.dsqr.theme.colors;
      tomlFormat = pkgs.formats.toml { };
      integrationArtifacts = pkgs.runCommand "herdr-${cfg.package.version}-agent-integrations" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p \
          "$out/codex" \
          "$out/claude" \
          "$out/pi/extensions"

        CODEX_HOME="$out/codex" ${getExe cfg.package} integration install codex
        CLAUDE_CONFIG_DIR="$out/claude" ${getExe cfg.package} integration install claude
        PI_CODING_AGENT_DIR="$out/pi" ${getExe cfg.package} integration install pi

        for hook in \
          "$out/codex/herdr-agent-state.sh" \
          "$out/claude/hooks/herdr-agent-state.sh"
        do
          substituteInPlace "$hook" \
            --replace-fail "python3" "${getExe pkgs.python3}"
        done
      '';

      layoutScript = pkgs.writeText "herdr-layouts.nu" ''
        const HERDR_LAYOUT_CONFIG = ${
          toNushell { } {
            binary = getExe cfg.package;
            inherit (cfg) agents;
            inherit (cfg.layouts)
              editorCommand
              maxProjects
              maxSwarmPanes
              ;
          }
        }

        ${builtins.readFile ./herdr-layouts.nu}
      '';

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
        worktrees.directory = "${config.xdg.stateHome}/herdr/worktrees";

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

        integrations = {
          codex.enable = mkEnableOption "the native Herdr Codex session hook" // {
            default = true;
          };

          claude.enable = mkEnableOption "the native Herdr Claude Code session hook" // {
            default = true;
          };

          pi.enable = mkEnableOption "the native Herdr Pi lifecycle and session extension" // {
            default = true;
          };

          artifacts = mkOption {
            type = nullOr package;
            default = null;
            internal = true;
            description = "Nix-generated official Herdr agent integration artifacts.";
          };
        };

        agents = mkOption {
          type = attrsOf (submodule {
            options = {
              kind = mkOption {
                type = str;
                description = "Canonical Herdr agent kind.";
              };

              args = mkOption {
                type = listOf str;
                default = [ ];
                description = "Arguments passed after `herdr agent start --`.";
              };
            };
          });
          default = {
            codex.kind = "codex";
            claude.kind = "claude";
            pi.kind = "pi";
          };
          description = "Agents available to tdl, tdlm, and tsl.";
        };

        layouts = {
          enable = mkEnableOption "Nushell tdl, tdlm, and tsl layout commands" // {
            default = true;
          };

          editorCommand = mkOption {
            type = str;
            default = "nvim .";
            description = "Nushell command started in the editor pane by tdl.";
          };

          maxProjects = mkOption {
            type = int;
            default = 10;
            description = "Maximum repositories tdlm creates in one invocation.";
          };

          maxSwarmPanes = mkOption {
            type = int;
            default = 6;
            description = "Maximum shared-checkout agent panes created by tsl.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = nuEnabled;
            message = "dsqr.home.desktop.ghostty.herdr requires dsqr.home.nu so new panes have the configured Nushell environment.";
          }
          {
            assertion = cfg.layouts.maxProjects > 0;
            message = "dsqr.home.desktop.ghostty.herdr.layouts.maxProjects must be positive.";
          }
          {
            assertion = cfg.layouts.maxSwarmPanes >= 2;
            message = "dsqr.home.desktop.ghostty.herdr.layouts.maxSwarmPanes must be at least two.";
          }
        ];

        dsqr.home.desktop.ghostty.herdr.integrations.artifacts = integrationArtifacts;

        home.packages = [ cfg.package ];

        programs.nushell.extraConfig = mkIf cfg.layouts.enable (mkAfter /* nu */ ''
          source ${layoutScript}
        '');

        xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" (
          recursiveUpdate defaultSettings cfg.settings
        );
      };
    };
}
