{
  config,
  hostName,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.dsqr.darwin.profiles.miniServer;
  userCfg = config.dsqr.darwin.personal.user;
  userName = if userCfg.name == null then "primary-user-unset" else userCfg.name;
  userHome = if userCfg.home == null then "/Users/${userName}" else userCfg.home;
in
{
  options.dsqr.darwin.profiles.miniServer = {
    enable = mkEnableOption "Mac mini server profile";

    desktop.enable = mkEnableOption "headless-ish desktop defaults for Mac mini servers" // {
      default = true;
    };

    exo.enable = mkEnableOption "Exo service for Mac mini servers" // {
      default = true;
    };

    monitoring.enable = mkEnableOption "Grafana Alloy log shipping for Mac mini servers" // {
      default = true;
    };

    power.enable = mkEnableOption "always-on power defaults for Mac mini servers" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = userCfg.name != null;
        message = "dsqr.darwin.profiles.miniServer requires dsqr.darwin.personal.user.name.";
      }
      {
        assertion = userCfg.home != null;
        message = "dsqr.darwin.profiles.miniServer requires dsqr.darwin.personal.user.home.";
      }
    ];

    dsqr.darwin = {
      determinate.enable = true;

      desktop = mkIf cfg.desktop.enable {
        dock.enable = false;
        maccy.enable = false;
        system.enable = false;
      };

      grafana = mkIf cfg.monitoring.enable {
        alloy.enable = true;
        loki = {
          enable = true;
          exo.enable = cfg.exo.enable;
        };
      };
    };

    dsqr.nix.settings = {
      substituters = [
        "https://cache.nixos.org/"
        "https://cache.flakehub.com"
        "https://exo.cachix.org"
      ];
      trusted-public-keys = [ "exo.cachix.org-1:okq7hl624TBeAR3kV+g39dUFSiaZgLRkLsFBCuJ2NZI=" ];
      trusted-users = [
        "root"
        userName
      ];
      connect-timeout = 30;
      download-attempts = 20;
      http-connections = 1;
      http2 = false;
      max-jobs = 2;
      stalled-download-timeout = 900;
    };

    home-manager.users.${userName} = { lib, ... }: {
      home.activation.ensureExoLogDirectory = mkIf cfg.exo.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
          mkdir -p "$HOME/Library/Logs/exo"
          touch "$HOME/Library/Logs/exo/exo.log"
        ''
      );

      launchd.agents.exo.config = mkIf cfg.exo.enable {
        StandardErrorPath = "${userHome}/Library/Logs/exo/exo.log";
        StandardOutPath = "${userHome}/Library/Logs/exo/exo.log";
      };

      services.exo.enable = cfg.exo.enable;

      dsqr.home = {
        aws.enable = false;
        bat.enable = false;
        claudeCode.enable = false;
        codex.enable = false;
        difftastic.enable = false;
        hushlogin.enable = false;
        ollama.enable = false;
        pi-bridge.enable = false;
        versionControl = {
          gh.enable = false;
          git.signing.enable = false;
          glab.enable = false;
          gpg.enable = false;
          lazygit.enable = false;
        };
        desktop = {
          browsers.helium.enable = false;
          codexbar.enable = false;
          ghostty.enable = false;
          hammerspoon.enable = false;
          obsidian.enable = false;
        };
        neovim = {
          initLua.enable = false;
          packages.enable = false;
          plugins.enable = false;
        };
        nu.integrations.enable = false;
        opencode.enable = false;
        packages = {
          containers.enable = false;
          databases.enable = false;
          debugging.enable = false;
          kubernetes.enable = false;
          media.enable = false;
          node.enable = false;
          signing.enable = false;
        };
      };
    };

    networking = {
      inherit hostName;
      computerName = hostName;
      localHostName = hostName;
    };

    system.activationScripts.miniClusterPower.text = mkIf cfg.power.enable /* bash */ ''
      /usr/bin/pmset -a sleep 0 \
        displaysleep 0 \
        disksleep 0 \
        standby 0 \
        autopoweroff 0 \
        womp 1 \
        tcpkeepalive 1 \
        autorestart 1 \
        powernap 1
    '';
  };
}
