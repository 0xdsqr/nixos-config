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
  exoHealthLogPath = "${exoLogDirectory}/health.log";
  exoPackage = inputs.exo.packages.${pkgs.stdenv.hostPlatform.system}.exo;
  exoHealth = pkgs.writeShellApplication {
    name = "exo-health";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      api_url="http://127.0.0.1:52415"
      check_interval=30
      recovery_threshold=3
      declare -A unhealthy_counts=()

      log() {
        printf '%s %s\n' "$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
      }

      recover_instance() {
        local instance_id="$1"
        local state="$2"
        local metadata model_id min_nodes instance_tag instance_meta sharding
        local pending_commands command_id removed placement payload response

        if ! metadata="$(
          printf '%s' "$state" | jq -er --arg instance_id "$instance_id" '
            .instances[$instance_id]
            | to_entries[0] as $tagged
            | $tagged.value.shardAssignments as $assignments
            | [
                $assignments.modelId,
                ($assignments.nodeToRunner | length | tostring),
                $tagged.key,
                (
                  $assignments.runnerToShard
                  | to_entries[0].value
                  | keys[0]
                  | if startswith("Pipeline") then "Pipeline"
                    elif startswith("Tensor") then "Tensor"
                    else error("unsupported sharding metadata")
                    end
                )
              ]
            | @tsv
          '
        )"; then
          log "unable to describe unhealthy instance $instance_id"
          return 1
        fi

        IFS=$'\t' read -r model_id min_nodes instance_tag sharding <<< "$metadata"
        instance_meta="''${instance_tag%Instance}"
        log "recovering instance=$instance_id model=$model_id nodes=$min_nodes meta=$instance_meta sharding=$sharding"

        if pending_commands="$(
          printf '%s' "$state" | jq -r --arg instance_id "$instance_id" '
            (.tasks // {})
            | to_entries[]
            | .value
            | to_entries[]
            | .value
            | select(
                .instanceId == $instance_id
                and (.taskStatus == "Pending" or .taskStatus == "Running")
                and .commandId != null
              )
            | .commandId
          ' | sort -u
        )"; then
          while IFS= read -r command_id; do
            [[ -n "$command_id" ]] || continue
            curl --fail --silent --show-error \
              --request POST \
              "$api_url/v1/cancel/$command_id" >/dev/null || true
          done <<< "$pending_commands"
        fi

        if ! curl --fail --silent --show-error \
          --request DELETE \
          "$api_url/instance/$instance_id" >/dev/null; then
          log "failed to delete unhealthy instance $instance_id"
          return 1
        fi

        removed=0
        for _ in $(seq 1 30); do
          if state="$(curl --fail --silent --show-error --max-time 5 "$api_url/state")" \
            && ! printf '%s' "$state" | jq -e --arg instance_id "$instance_id" \
              '.instances[$instance_id] != null' >/dev/null; then
            removed=1
            break
          fi
          sleep 2
        done

        if [[ "$removed" -ne 1 ]]; then
          log "instance $instance_id did not finish shutting down"
          return 1
        fi

        if ! placement="$(
          curl --fail --silent --show-error --get \
            "$api_url/instance/placement" \
            --data-urlencode "model_id=$model_id" \
            --data-urlencode "sharding=$sharding" \
            --data-urlencode "instance_meta=$instance_meta" \
            --data-urlencode "min_nodes=$min_nodes"
        )"; then
          log "no replacement placement available for $model_id"
          return 1
        fi

        if ! payload="$(jq -cn --argjson instance "$placement" '{ instance: $instance }')"; then
          log "invalid replacement placement returned for $model_id"
          return 1
        fi

        if ! response="$(
          curl --fail --silent --show-error \
            --request POST \
            --header "Content-Type: application/json" \
            --data-binary "$payload" \
            "$api_url/instance"
        )"; then
          log "failed to recreate instance for $model_id"
          return 1
        fi

        log "replacement accepted command=$(printf '%s' "$response" | jq -r '.command_id // "unknown"')"
      }

      log "health supervisor started"

      while true; do
        sleep "$check_interval"

        if ! state="$(curl --fail --silent --show-error --max-time 5 "$api_url/state")"; then
          log "API health check failed; launchd remains responsible for process restarts"
          continue
        fi

        if ! unhealthy_ids="$(
          printf '%s' "$state" | jq -r '
            . as $state
            | (.instances // {})
            | to_entries[]
            | .key as $instance_id
            | (.value | to_entries[0].value.shardAssignments.nodeToRunner | .[]) as $runner_id
            | ($state.runners[$runner_id] // null) as $runner
            | if $runner == null then
                $instance_id
              else
                ($runner | keys[0]) as $status
                | select(
                    $status == "RunnerIdle"
                    or $status == "RunnerShuttingDown"
                    or $status == "RunnerShutdown"
                    or $status == "RunnerFailed"
                  )
                | $instance_id
              end
          ' | sort -u
        )"; then
          log "state health evaluation failed"
          continue
        fi

        for known_id in "''${!unhealthy_counts[@]}"; do
          if ! grep -Fqx "$known_id" <<< "$unhealthy_ids"; then
            unset "unhealthy_counts[$known_id]"
          fi
        done

        while IFS= read -r instance_id; do
          [[ -n "$instance_id" ]] || continue
          unhealthy_counts[$instance_id]="$(( ''${unhealthy_counts[$instance_id]:-0} + 1 ))"
          log "unhealthy instance=$instance_id check=''${unhealthy_counts[$instance_id]}/$recovery_threshold"

          if (( unhealthy_counts[$instance_id] >= recovery_threshold )); then
            unset "unhealthy_counts[$instance_id]"
            recover_instance "$instance_id" "$state" || log "automatic recovery failed for $instance_id"
          fi
        done <<< "$unhealthy_ids"
      done
    '';
  };
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

    exo.autoRecover = mkOption {
      type = bool;
      default = true;
      description = "Automatically recreate Exo instances whose assigned runner processes are no longer usable.";
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
      /usr/bin/touch ${lib.escapeShellArg exoHealthLogPath}
      /usr/sbin/chown ${lib.escapeShellArg "${userName}:staff"} \
        ${lib.escapeShellArg exoLogPath} \
        ${lib.escapeShellArg exoHealthLogPath}
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

    launchd.daemons."exo-health" = mkIf (cfg.exo.enable && cfg.exo.forceMaster && cfg.exo.autoRecover) {
      serviceConfig = {
        UserName = userName;
        ProgramArguments = [ (lib.getExe exoHealth) ];
        KeepAlive = true;
        ProcessType = "Background";
        RunAtLoad = true;
        ThrottleInterval = 30;
        WorkingDirectory = userHome;
        StandardErrorPath = exoHealthLogPath;
        StandardOutPath = exoHealthLogPath;
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
