{
  flake.homeModules.ssh =
    { config, lib, ... }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.lists) optionals;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatLines optionalString;
      inherit (lib.types)
        attrsOf
        lines
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.home.ssh;

      hostOptions = { name, ... }: {
        options = {
          hostName = mkOption {
            type = str;
            default = name;
            description = "SSH HostName value.";
          };

          user = mkOption {
            type = nullOr str;
            default = null;
            description = "SSH User value.";
          };

          identityFile = mkOption {
            type = nullOr str;
            default = null;
            description = "SSH IdentityFile value.";
          };

          strictHostKeyChecking = mkOption {
            type = nullOr str;
            default = null;
            description = "SSH StrictHostKeyChecking value.";
          };

          extraConfig = mkOption {
            type = lines;
            default = "";
            description = "Extra lines appended to this SSH host block.";
          };
        };
      };

      renderHost =
        defaults: name: host:
        let
          user = if host.user != null then host.user else defaults.user;
          identityFile = if host.identityFile != null then host.identityFile else defaults.identityFile;
          strictHostKeyChecking =
            if host.strictHostKeyChecking != null then host.strictHostKeyChecking else defaults.strictHostKeyChecking;
        in
        /* sshconfig */ ''
          Host ${name}
            HostName ${host.hostName}
        ''
        + optionalString (user != null) "  User ${user}\n"
        + optionalString (identityFile != null) "  IdentityFile ${identityFile}\n"
        + optionalString (strictHostKeyChecking != null) "  StrictHostKeyChecking ${strictHostKeyChecking}\n"
        + optionalString (host.extraConfig != "") host.extraConfig;

      hostBlocks = mapAttrsToList (renderHost {
        inherit (cfg.homelab) identityFile strictHostKeyChecking user;
      }) cfg.homelab.hosts;

      backupHostBlocks = mapAttrsToList (
        name: host:
        renderHost {
          identityFile =
            if cfg.homelab.backup.identityFile != null then cfg.homelab.backup.identityFile else cfg.homelab.identityFile;
          strictHostKeyChecking =
            if cfg.homelab.backup.strictHostKeyChecking != null then
              cfg.homelab.backup.strictHostKeyChecking
            else
              cfg.homelab.strictHostKeyChecking;
          inherit (cfg.homelab.backup) user;
        } "${name}-backup" host
      ) cfg.homelab.backup.hosts;
    in
    {
      options.dsqr.home.ssh = {
        enable = mkEnableOption "SSH configuration" // {
          default = true;
        };

        defaults.enable = mkEnableOption "base SSH defaults block" // {
          default = true;
        };

        homelab.enable = mkEnableOption "generated homelab SSH host entries" // {
          default = false;
        };

        homelab.user = mkOption {
          type = nullOr str;
          default = null;
          description = "Default SSH user for generated homelab host entries.";
        };

        homelab.identityFile = mkOption {
          type = nullOr str;
          default = null;
          description = "Default SSH identity file for generated homelab host entries.";
        };

        homelab.strictHostKeyChecking = mkOption {
          type = nullOr str;
          default = "accept-new";
          description = "Default StrictHostKeyChecking value for generated homelab host entries.";
        };

        homelab.hosts = mkOption {
          type = attrsOf (submodule hostOptions);
          default = { };
          description = "Generated homelab SSH host entries keyed by SSH host alias.";
        };

        homelab.backup.enable = mkEnableOption "generated backup SSH host entries";

        homelab.backup.user = mkOption {
          type = nullOr str;
          default = "backup";
          description = "Default SSH user for generated backup host entries.";
        };

        homelab.backup.identityFile = mkOption {
          type = nullOr str;
          default = null;
          description = "Default SSH identity file for generated backup host entries.";
        };

        homelab.backup.strictHostKeyChecking = mkOption {
          type = nullOr str;
          default = null;
          description = "Default StrictHostKeyChecking value for generated backup host entries.";
        };

        homelab.backup.hosts = mkOption {
          type = attrsOf (submodule hostOptions);
          default = { };
          description = "Generated backup SSH host entries keyed by base SSH host alias.";
        };

        extraConfig = mkOption {
          type = lines;
          default = "";
          description = "Additional SSH config appended after the generated homelab entries.";
        };
      };

      config = mkIf cfg.enable {
        home.file.".ssh/config".text =
          concatLines (
            optionals cfg.defaults.enable [
              /* sshconfig */ ''
                Host *
                  IdentitiesOnly yes
              ''
            ]
            ++ optionals cfg.homelab.enable hostBlocks
            ++ optionals (cfg.homelab.enable && cfg.homelab.backup.enable) backupHostBlocks
          )
          + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
      };
    };
}
