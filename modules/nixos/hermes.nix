{ inputs, ... }: {
  flake.nixosModules.hermes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.lists) concatLists optional;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkOption;
      inherit (lib.strings) concatStringsSep escapeShellArgs;
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
      configMergeScript = pkgs.callPackage (inputs.hermes-agent + /nix/configMergeScript.nix) { };
      configYamlMode = if upstream.addToSystemPackages then "0660" else "0640";
      profiles = filterAttrs (_: profile: profile.enable) cfg.profiles;
      profileHome = name: "${upstream.stateDir}/.hermes/profiles/${name}";
      profileConfig =
        name: profile:
        pkgs.writeText "hermes-profile-${name}.json" (
          builtins.toJSON (lib.recursiveUpdate { terminal.cwd = upstream.workingDirectory; } profile.settings)
        );
      profileSoul = name: profile: pkgs.writeText "hermes-profile-${name}-SOUL.md" profile.soul;
      # Non-secret variables only; secrets are appended from environmentFiles at
      # activation so they never reach the Nix store.
      profileEnv =
        name: profile:
        pkgs.writeText "hermes-profile-${name}.env" (
          concatStringsSep "" (mapAttrsToList (key: value: "${key}=${builtins.toJSON value}\n") profile.environment)
        );

      # Upstream renders the default profile's .env after secrets are decrypted;
      # profile .env files need the agenix paths too.
      secretsActivationDeps = builtins.filter (name: config.system.activationScripts ? ${name}) [
        "agenixInstall"
        "agenixChown"
        "setupSecrets"
      ];

      profileModule = _: {
        options = {
          enable = mkOption {
            type = bool;
            default = true;
            description = "Enable this named Hermes profile on the host gateway.";
          };

          settings = mkOption {
            type = attrs;
            default = { };
            description = "Declarative Hermes configuration for this profile.";
          };

          environment = mkOption {
            type = attrsOf str;
            default = { };
            description = "Non-secret variables written to this profile's .env.";
          };

          environmentFiles = mkOption {
            type = listOf str;
            default = [ ];
            description = "Runtime secret files appended to this profile's .env.";
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
        description = ''
          Named Hermes profiles served by the upstream host gateway. Hermes
          multiplexes every profile under $HERMES_HOME/profiles through the one
          `hermes-agent` service, so a profile is its config.yaml, .env, and
          SOUL.md; it never gets a gateway service of its own.
        '';
      };

      config = mkIf (upstream.enable && profiles != { }) {
        # One host gateway serves every profile (the only supported topology
        # since v0.23). Make the default profile's choice explicit.
        services.hermes-agent.settings.gateway.multiplex_profiles = true;

        system.activationScripts.hermes-agent-profiles =
          lib.stringAfter ([ "hermes-agent-setup" ] ++ secretsActivationDeps)
            (
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
                    ${configMergeScript} ${profileConfig name profile} ${home}/config.yaml
                    chown ${upstream.user}:${upstream.group} ${home}/config.yaml
                    chmod ${configYamlMode} ${home}/config.yaml

                    _hermes_env="$(mktemp)"
                    cat ${profileEnv name profile} > "$_hermes_env"
                    for _hermes_env_file in ${escapeShellArgs profile.environmentFiles}; do
                      if [[ -r "$_hermes_env_file" ]]; then
                        cat "$_hermes_env_file" >> "$_hermes_env"
                        printf '\n' >> "$_hermes_env"
                      else
                        echo "hermes profile ${name}: missing environment file $_hermes_env_file" >&2
                      fi
                    done
                    install -o ${upstream.user} -g ${upstream.group} -m 0640 "$_hermes_env" ${home}/.env
                    rm -f "$_hermes_env"
                    ${lib.optionalString (profile.soul != null) /* bash */ ''
                      install -o ${upstream.user} -g ${upstream.group} -m 0640 \
                        ${profileSoul name profile} ${home}/SOUL.md
                    ''}
                  ''
                ) profiles
              )
            );

        # Served profiles load their config once at gateway start, so the host
        # gateway restarts whenever a profile's declared state changes.
        systemd.services.hermes-agent.restartTriggers = concatLists (
          mapAttrsToList (
            name: profile:
            [
              (profileConfig name profile)
              (profileEnv name profile)
            ]
            ++ optional (profile.soul != null) (profileSoul name profile)
          ) profiles
        );
      };
    };
}
