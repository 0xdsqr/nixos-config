{
  flake.commonModules.tailscale =
    { hostName, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.dsqr.tailscale = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable Tailscale for this host.";
        };

        hostName = mkOption {
          type = types.str;
          default = hostName;
          description = "Hostname to register with Tailscale.";
        };

        authKeyAgeFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Age-encrypted Tailscale auth key file used for automatic enrollment.";
        };

        tags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "tag:server" ];
          description = "Tags to apply during `tailscale up`.";
        };

        acceptDns = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the node should accept Tailscale DNS settings.";
        };

        extraUpFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional flags passed to `tailscale up`.";
        };

        nixos.useRoutingFeatures = mkOption {
          type = types.enum [
            "none"
            "client"
            "server"
            "both"
          ];
          default = "client";
          description = "Routing mode for NixOS Tailscale nodes.";
        };
      };
    };

  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      inherit (lib) mkIf optionalAttrs optionals;
      cfg = config.dsqr.tailscale;
      upFlags = [
        "--hostname=${cfg.hostName}"
        "--accept-dns=${if cfg.acceptDns then "true" else "false"}"
      ]
      ++ optionals (cfg.tags != [ ]) [ "--advertise-tags=${lib.concatStringsSep "," cfg.tags}" ]
      ++ cfg.extraUpFlags;
    in
    mkIf cfg.enable {
      age.secrets = optionalAttrs (cfg.authKeyAgeFile != null) {
        tailscaleAuthKey = {
          file = cfg.authKeyAgeFile;
          owner = "root";
          mode = "0400";
        };
      };

      services.tailscale = {
        enable = true;
        inherit (cfg.nixos) useRoutingFeatures;
        extraUpFlags = upFlags;
      }
      // optionalAttrs (cfg.authKeyAgeFile != null) { authKeyFile = config.age.secrets.tailscaleAuthKey.path; };
    };

  flake.darwinModules.tailscale =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        mkAfter
        mkIf
        mkMerge
        optionals
        ;
      cfg = config.dsqr.tailscale;
      upFlags = [
        "--hostname=${cfg.hostName}"
        "--accept-dns=${if cfg.acceptDns then "true" else "false"}"
      ]
      ++ optionals (cfg.tags != [ ]) [ "--advertise-tags=${concatStringsSep "," cfg.tags}" ]
      ++ cfg.extraUpFlags;
      upFlagsString = concatStringsSep " " (map lib.escapeShellArg upFlags);
      mkTailscaleAuthScript =
        secretPath:
        pkgs.writeShellScript "tailscale-auth" ''
          set -eu

          app_cli="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
          cli="${lib.getExe pkgs.tailscale}"

          if [ -x "$app_cli" ]; then
            cli="$app_cli"
          fi

          status="$("$cli" status --json 2>/dev/null || true)"
          if printf '%s' "$status" | ${lib.getExe pkgs.gnugrep} -q '"BackendState":"Running"'; then
            exit 0
          fi

          if [ ! -r "${secretPath}" ]; then
            exit 0
          fi

          auth_key="$(${lib.getExe pkgs.coreutils} tr -d '\n' < "${secretPath}")"
          exec "$cli" up --auth-key="$auth_key" ${upFlagsString}
        '';
    in
    mkIf cfg.enable (mkMerge [
      {
        homebrew.casks = [ "tailscale-app" ];
        environment.systemPackages = [ pkgs.tailscale ];
      }

      (mkIf (cfg.authKeyAgeFile != null) {
        age.identityPaths = mkAfter [ "/Users/${config.system.primaryUser}/.ssh/dsqr_homelab_ed25519" ];

        age.secrets.tailscaleAuthKey = {
          file = cfg.authKeyAgeFile;
          owner = config.system.primaryUser;
          mode = "0400";
        };

        launchd.user.agents.tailscale-auth = {
          serviceConfig.Program = mkTailscaleAuthScript config.age.secrets.tailscaleAuthKey.path;
          serviceConfig.RunAtLoad = true;
          serviceConfig.KeepAlive = false;
          managedBy = "dsqr.tailscale.enable";
        };
      })
    ]);

  flake.homeModules.tailscale =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      inherit (lib.meta) getExe;
    in
    mkIf osConfig.dsqr.tailscale.enable {
      programs.nushell.aliases.ts = if osConfig.nixpkgs.hostPlatform.isDarwin then "tailscale" else getExe pkgs.tailscale;

      packages = mkIf osConfig.nixpkgs.hostPlatform.isLinux [ pkgs.tailscale ];
    };
}
