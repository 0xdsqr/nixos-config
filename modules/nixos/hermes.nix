{ inputs, ... }: {
  flake.nixosModules.hermes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs' mapAttrsToList nameValuePair;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.types)
        attrsOf
        bool
        lines
        listOf
        nullOr
        package
        path
        str
        submodule
        unspecified
        ;

      cfg = config.dsqr.nixos.hermes;
      defaultPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;

      instanceModule = _: {
        options = {
          environmentAgeFile = mkOption {
            type = nullOr path;
            default = null;
            description = "Encrypted environment file containing DISCORD_BOT_TOKEN.";
          };

          allowedUsers = mkOption {
            type = listOf str;
            default = [ ];
            description = "Discord user IDs authorized to use the agent.";
          };

          allowedRoles = mkOption {
            type = listOf str;
            default = [ ];
            description = "Discord role IDs authorized to use the agent.";
          };

          allowedChannels = mkOption {
            type = listOf str;
            default = [ ];
            description = "Discord channel IDs in which the agent may respond; empty permits every channel.";
          };

          freeResponseChannels = mkOption {
            type = listOf str;
            default = [ ];
            description = "Discord channel IDs where an explicit mention is not required.";
          };

          homeChannel = mkOption {
            type = nullOr str;
            default = null;
            description = "Discord channel ID for proactive messages.";
          };

          requireMention = mkOption {
            type = bool;
            default = true;
            description = "Require an explicit mention outside free-response channels.";
          };

          toolsets = mkOption {
            type = listOf str;
            default = [ "hermes-discord" ];
            description = "Hermes toolsets enabled for the Discord gateway.";
          };

          disabledSkills = mkOption {
            type = listOf str;
            default = [ ];
            description = "Bundled Hermes skills disabled for this agent.";
          };

          settings = mkOption {
            type = attrsOf unspecified;
            default = { };
            description = "Additional declarative Hermes configuration.";
          };

          systemPrompt = mkOption {
            type = lines;
            default = "";
            description = "Optional SOUL.md contents for this agent.";
          };

          memoryHigh = mkOption {
            type = str;
            default = "1536M";
            description = "Memory pressure threshold for the service.";
          };

          memoryMax = mkOption {
            type = str;
            default = "2G";
            description = "Hard memory limit for the service.";
          };

          cpuQuota = mkOption {
            type = str;
            default = "150%";
            description = "CPU quota for the service.";
          };
        };
      };

      stateDirectory = name: "/var/lib/hermes-agent-${name}";
      hermesHome = name: "${stateDirectory name}/.hermes";
      workspace = name: "${stateDirectory name}/workspace";
      userName = name: "hermes-${name}";
      secretName = name: "hermes-agent-${name}-environment";

      configFile =
        name: instance:
        pkgs.writeText "hermes-agent-${name}-config.yaml" (
          builtins.toJSON (
            lib.recursiveUpdate {
              terminal.cwd = workspace name;
              inherit (instance) toolsets;
              skills.disabled = instance.disabledSkills;
            } instance.settings
          )
        );

      soulFile = name: instance: pkgs.writeText "hermes-agent-${name}-SOUL.md" instance.systemPrompt;

      discordEnvironment =
        instance:
        {
          DISCORD_ALLOWED_USERS = concatStringsSep "," instance.allowedUsers;
          DISCORD_ALLOWED_ROLES = concatStringsSep "," instance.allowedRoles;
          DISCORD_ALLOWED_CHANNELS = concatStringsSep "," instance.allowedChannels;
          DISCORD_FREE_RESPONSE_CHANNELS = concatStringsSep "," instance.freeResponseChannels;
          DISCORD_REQUIRE_MENTION = if instance.requireMention then "true" else "false";
          DISCORD_ALLOW_BOTS = "none";
        }
        // lib.optionalAttrs (instance.homeChannel != null) { DISCORD_HOME_CHANNEL = instance.homeChannel; };
    in
    {
      options.dsqr.nixos.hermes = {
        enable = mkEnableOption "multi-instance Hermes agents";

        package = mkOption {
          type = package;
          default = defaultPackage;
          description = "Hermes package shared by every agent instance.";
        };

        instances = mkOption {
          type = attrsOf (submodule instanceModule);
          default = { };
          description = "Isolated Hermes agent instances.";
        };
      };

      config = mkIf cfg.enable {
        assertions = mapAttrsToList (name: instance: {
          assertion = instance.environmentAgeFile != null && (instance.allowedUsers != [ ] || instance.allowedRoles != [ ]);
          message = "Hermes instance ${name} requires an environmentAgeFile and an authorized Discord user or role.";
        }) cfg.instances;

        age.secrets = mapAttrs' (
          name: instance:
          nameValuePair (secretName name) {
            file = instance.environmentAgeFile;
            owner = userName name;
            group = userName name;
            mode = "0400";
          }
        ) cfg.instances;

        users.groups = mapAttrs' (name: _: nameValuePair (userName name) { }) cfg.instances;
        users.users = mapAttrs' (
          name: _:
          nameValuePair (userName name) {
            isSystemUser = true;
            group = userName name;
            home = stateDirectory name;
            createHome = true;
          }
        ) cfg.instances;

        systemd.tmpfiles.rules = lib.concatLists (
          mapAttrsToList (name: _: [
            "d ${stateDirectory name} 0750 ${userName name} ${userName name} -"
            "d ${hermesHome name} 0700 ${userName name} ${userName name} -"
            "d ${hermesHome name}/cron 0700 ${userName name} ${userName name} -"
            "d ${hermesHome name}/logs 0700 ${userName name} ${userName name} -"
            "d ${hermesHome name}/memories 0700 ${userName name} ${userName name} -"
            "d ${hermesHome name}/sessions 0700 ${userName name} ${userName name} -"
            "d ${workspace name} 0700 ${userName name} ${userName name} -"
          ]) cfg.instances
        );

        systemd.services = mapAttrs' (
          name: instance:
          nameValuePair "hermes-agent-${name}" {
            description = "Hermes Agent (${name})";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "agenix.service"
            ];
            wants = [ "network-online.target" ];

            environment = discordEnvironment instance // {
              HOME = stateDirectory name;
              HERMES_HOME = hermesHome name;
              HERMES_MANAGED = "true";
            };

            path = [
              cfg.package
              pkgs.bash
              pkgs.coreutils
              pkgs.git
            ];

            preStart = ''
              install -o ${userName name} -g ${userName name} -m 0600 ${configFile name instance} ${hermesHome name}/config.yaml
              touch ${hermesHome name}/.managed
              chown ${userName name}:${userName name} ${hermesHome name}/.managed
              chmod 0600 ${hermesHome name}/.managed
              ${lib.optionalString (instance.systemPrompt != "") ''
                install -o ${userName name} -g ${userName name} -m 0600 ${soulFile name instance} ${workspace name}/SOUL.md
              ''}
            '';

            serviceConfig = {
              User = userName name;
              Group = userName name;
              WorkingDirectory = workspace name;
              EnvironmentFile = "/run/agenix/${secretName name}";
              ExecStart = "${getExe cfg.package} gateway";
              Restart = "on-failure";
              RestartSec = "10s";
              UMask = "0077";

              MemoryHigh = instance.memoryHigh;
              MemoryMax = instance.memoryMax;
              CPUQuota = instance.cpuQuota;
              TasksMax = 512;

              NoNewPrivileges = true;
              PrivateDevices = true;
              PrivateTmp = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectSystem = "strict";
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
                "AF_UNIX"
              ];
              RestrictSUIDSGID = true;
              LockPersonality = true;
              CapabilityBoundingSet = "";
              ReadWritePaths = [ (stateDirectory name) ];
            };
          }
        ) cfg.instances;

        environment.systemPackages = mapAttrsToList (
          name: _:
          pkgs.writeShellScriptBin "hermes-${name}" ''
            export HOME=${stateDirectory name}
            export HERMES_HOME=${hermesHome name}
            exec ${getExe cfg.package} "$@"
          ''
        ) cfg.instances;
      };
    };
}
