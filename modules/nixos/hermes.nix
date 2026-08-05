{ inputs, ... }: {
  flake.nixosModules.hermes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrs'
        mapAttrsToList
        nameValuePair
        ;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkOption;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.types)
        attrs
        attrsOf
        bool
        lines
        listOf
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.nixos.hermes;
      upstream = config.services.hermes-agent;
      profiles = filterAttrs (_: profile: profile.enable) cfg.profiles;
      profileHome = name: "${upstream.stateDir}/.hermes/profiles/${name}";
      profileConfig =
        name: profile:
        pkgs.writeText "hermes-profile-${name}.json" (
          builtins.toJSON (lib.recursiveUpdate { terminal.cwd = upstream.workingDirectory; } profile.settings)
        );
      profileSoul = name: profile: pkgs.writeText "hermes-profile-${name}-SOUL.md" profile.soul;

      profileModule = _: {
        options = {
          enable = mkOption {
            type = bool;
            default = true;
            description = "Enable this named Hermes profile and its gateway service.";
          };

          settings = mkOption {
            type = attrs;
            default = { };
            description = "Declarative Hermes configuration for this profile.";
          };

          environment = mkOption {
            type = attrsOf str;
            default = { };
            description = "Non-secret environment variables for this profile.";
          };

          environmentFiles = mkOption {
            type = listOf str;
            default = [ ];
            description = "Runtime secret files merged into this profile's environment.";
          };

          soul = mkOption {
            type = nullOr lines;
            default = null;
            description = "Optional SOUL.md contents for this profile.";
          };
        };
      };
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      options.dsqr.nixos.hermes.profiles = mkOption {
        type = attrsOf (submodule profileModule);
        default = { };
        description = "Named Hermes profiles managed alongside the upstream default service.";
      };

      config = mkIf (upstream.enable && profiles != { }) {
        system.activationScripts.hermes-agent-profiles = lib.stringAfter [ "hermes-agent-setup" ] (
          concatStringsSep "\n" (
            mapAttrsToList (
              name: profile:
              let
                home = profileHome name;
              in
              /* bash */ ''
                if [[ ! -d ${home} ]]; then
                  ${pkgs.util-linux}/bin/runuser -u ${upstream.user} -- \
                    env HOME=${upstream.stateDir} HERMES_HOME=${upstream.stateDir}/.hermes \
                    ${getExe upstream.package} profile create ${name} --no-alias
                fi

                install -d -o ${upstream.user} -g ${upstream.group} -m 2770 ${home}
                install -o ${upstream.user} -g ${upstream.group} -m 0640 \
                  ${profileConfig name profile} ${home}/config.yaml
                ${lib.optionalString (profile.soul != null) /* bash */ ''
                  install -o ${upstream.user} -g ${upstream.group} -m 0640 \
                    ${profileSoul name profile} ${home}/SOUL.md
                ''}
              ''
            ) profiles
          )
        );

        systemd.services = mapAttrs' (
          name: profile:
          nameValuePair "hermes-agent-${name}" {
            description = "Hermes Agent Gateway (${name})";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];

            environment = {
              HOME = upstream.stateDir;
              HERMES_HOME = "${upstream.stateDir}/.hermes";
              HERMES_MANAGED = "true";
            }
            // profile.environment;

            path = [
              upstream.package
              pkgs.bash
              pkgs.coreutils
              pkgs.git
            ]
            ++ upstream.extraPackages;

            serviceConfig = {
              User = upstream.user;
              Group = upstream.group;
              WorkingDirectory = upstream.workingDirectory;
              ExecStart = "${getExe upstream.package} --profile ${name} gateway run --replace";
              EnvironmentFile = profile.environmentFiles;
              Restart = upstream.restart;
              RestartSec = upstream.restartSec;
              UMask = "0007";

              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = false;
              ReadWritePaths = [
                upstream.stateDir
                upstream.workingDirectory
              ];
              PrivateTmp = true;
            };
          }
        ) profiles;
      };
    };
}
