{
  config,
  hostName,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optional;
  inherit (lib.modules) mkAfter mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool str;

  cfg = config.dsqr.darwin.profiles.miniServer;
  userCfg = config.dsqr.darwin.personal.user;
  userName = if userCfg.name == null then "primary-user-unset" else userCfg.name;
  userHome = if userCfg.home == null then "/Users/${userName}" else userCfg.home;
  exoLogDirectory = "${userHome}/Library/Logs/exo";
  exoLogPath = "${exoLogDirectory}/exo.log";
  exoPackage = inputs.exo.packages.${pkgs.stdenv.hostPlatform.system}.exo;
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

    exo.clusterNamespace = mkOption {
      type = str;
      default = "dsqr-mini-cluster";
      description = "Shared libp2p namespace used to isolate the Mac mini Exo cluster.";
    };

    exo.forceMaster = mkOption {
      type = bool;
      default = hostName == "srv-mini-master";
      description = "Whether this Exo node should have priority in master election.";
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
      bat.enable = false;
      determinate.enable = true;
      homebrew.enable = false;
      packages.screen.enable = false;

      desktop = mkMerge [
        { tailscale.mode = "daemon"; }

        (mkIf cfg.desktop.enable {
          browsers.helium.policy.enable = false;
          dock.enable = false;
          docker.enable = false;
          lapdog.enable = false;
          maccy.enable = false;
          obsidian.enable = false;
          spotify.enable = false;
          system.enable = false;
        })
      ];

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
      home.packages = lib.optional cfg.exo.enable exoPackage;

      home.activation.retireLegacyExoAgent = mkIf cfg.exo.enable (
        lib.hm.dag.entryBefore [ "setupLaunchAgents" ] /* bash */ ''
          legacy_agent="$HOME/Library/LaunchAgents/org.nix-community.home.exo.plist"
          legacy_backup="$legacy_agent.before-system-exo"

          if [[ -f "$legacy_agent" ]] \
            && [[ "$(/usr/bin/plutil -extract Label raw -o - "$legacy_agent" 2>/dev/null || true)" == "org.nix-community.home.exo" ]]; then
            /bin/launchctl bootout "gui/$UID/org.nix-community.home.exo" >/dev/null 2>&1 || true

            if [[ -e "$legacy_backup" ]]; then
              run rm -f "$legacy_agent"
            else
              run mv "$legacy_agent" "$legacy_backup"
            fi
          fi
        ''
      );

      dsqr.home = {
        aws.enable = false;
        bat.enable = false;
        claudeCode.enable = false;
        codex.enable = false;
        difftastic.enable = false;
        hushlogin.enable = false;
        ollama.enable = false;
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

    system.activationScripts.preActivation.text = mkIf cfg.exo.enable /* bash */ ''
      /usr/bin/install -d -m 0755 -o ${lib.escapeShellArg userName} -g staff ${lib.escapeShellArg exoLogDirectory}
      /usr/bin/touch ${lib.escapeShellArg exoLogPath}
      /usr/sbin/chown ${lib.escapeShellArg "${userName}:staff"} ${lib.escapeShellArg exoLogPath}
    '';

    launchd.daemons.exo = mkIf cfg.exo.enable {
      serviceConfig = {
        UserName = userName;
        ProgramArguments = [
          (lib.getExe exoPackage)
          # MLX fast synchronization can permanently deadlock distributed
          # Ring inference on Apple silicon; Exo exposes this safe fallback.
          "--no-fast-synch"
        ]
        ++ optional cfg.exo.forceMaster "--force-master";
        EnvironmentVariables = {
          EXO_LIBP2P_NAMESPACE = cfg.exo.clusterNamespace;
          HOME = userHome;
          LOGNAME = userName;
          USER = userName;
        };
        KeepAlive = true;
        ProcessType = "Interactive";
        RunAtLoad = true;
        WorkingDirectory = userHome;
        StandardErrorPath = exoLogPath;
        StandardOutPath = exoLogPath;
      };
    };

    networking = {
      inherit hostName;
      computerName = hostName;
      localHostName = hostName;
    };

    power = mkIf cfg.power.enable {
      restartAfterFreeze = true;
      restartAfterPowerFailure = true;

      sleep = {
        allowSleepByPowerButton = false;
        computer = "never";
        display = "never";
        harddisk = "never";
      };
    };

    system.activationScripts.power.text = mkIf cfg.power.enable (mkAfter /* bash */ ''
      /usr/bin/pmset -a \
        standby 0 \
        powermode 2 \
        womp 1 \
        tcpkeepalive 1 \
        powernap 1
    '');
  };
}
