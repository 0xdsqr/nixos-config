{
  flake.nixosModules.restic =
    {
      config,
      hostMeta,
      keys,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.lists) elem optional;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        listOf
        nullOr
        package
        path
        str
        ;

      backupHost = if config.networking.hostName == "srv-lx-khaos" then "srv-lx-beacon" else null;

      cfg = config.dsqr.nixos.restic;
      isReceiver = elem config.networking.hostName cfg.receiverHosts;
      hasPasswordAgeFile = cfg.passwordAgeFile != null && builtins.pathExists cfg.passwordAgeFile;
    in
    {
      options = {
        dsqr.nixos.restic = {
          enable = mkEnableOption "Enable the shared restic backup baseline";

          hosts = mkOption {
            type = listOf str;
            default = optional (backupHost != null) backupHost;
            description = "Hosts that receive this machine's restic backups.";
          };

          receiverHosts = mkOption {
            type = listOf str;
            default = [ "srv-lx-beacon" ];
            description = "Hosts that receive restic backups over SSH.";
          };

          package = mkOption {
            type = package;
            default = pkgs.restic;
            defaultText = "pkgs.restic";
            description = "restic package to install.";
          };

          passwordAgeFile = mkOption {
            type = nullOr path;
            default = hostMeta.path + "/restic.password.age";
            description = "Encrypted age file that stores the restic repository password.";
          };
        };

        services.restic.hosts = mkOption {
          type = listOf str;
          default = cfg.hosts;
          description = "Computed list of hosts that receive this machine's restic backups.";
        };
      };

      config = mkIf cfg.enable (
        mkIf isReceiver {
          users.users.backup = {
            description = "Backup";
            isNormalUser = true;
            openssh.authorizedKeys.keys = keys.all;
          };
        }
        // mkIf (config.services.restic.hosts != [ ] && hasPasswordAgeFile) {
          age.secrets.resticPassword.file = cfg.passwordAgeFile;

          environment.systemPackages = [ cfg.package ];

          services.restic.backups = genAttrs config.services.restic.hosts (host: {
            repository = "sftp:backup@${host}:${config.networking.hostName}-backup";
            passwordFile = config.age.secrets.resticPassword.path;
            initialize = true;
            extraOptions = [
              "sftp.command='ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=accept-new backup@${host} -s sftp'"
            ];

            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
            ];
          });
        }
      );
    };
}
