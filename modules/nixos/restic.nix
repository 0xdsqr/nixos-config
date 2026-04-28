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
      inherit (lib) genAttrs mkIf mkOption;
      inherit (lib.lists) elem optional;
      inherit (lib.types) listOf str;

      backupHost = if config.networking.hostName == "srv-lx-khaos" then "srv-lx-beacon" else null;

      resticHosts = optional (backupHost != null) backupHost;
      receiverHosts = [ "srv-lx-beacon" ];
      isReceiver = elem config.networking.hostName receiverHosts;
      passwordAgeFile = hostMeta.path + "/restic.password.age";
      hasPasswordAgeFile = builtins.pathExists passwordAgeFile;
    in
    {
      options.services.restic.hosts = mkOption {
        type = listOf str;
        default = resticHosts;
        description = "Computed list of hosts that receive this machine's restic backups.";
      };

      config =
        mkIf isReceiver {
          users.users.backup = {
            description = "Backup";
            isNormalUser = true;
            openssh.authorizedKeys.keys = keys.all;
          };
        }
        // mkIf (config.services.restic.hosts != [ ] && hasPasswordAgeFile) {
          age.secrets.resticPassword.file = passwordAgeFile;

          environment.systemPackages = [ pkgs.restic ];

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
        };
    };
}
