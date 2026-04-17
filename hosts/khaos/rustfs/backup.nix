{ config, lib, ... }:
let
  inherit (lib) genAttrs' mkIf nameValuePair;
  resticHosts = config.services.restic.hosts;
in
{
  config = mkIf (resticHosts != [ ]) {
    services.restic.backups = genAttrs' resticHosts (
      host:
      let
        hostBackup = config.services.restic.backups.${host};
      in
      nameValuePair "rustfs-${host}" {
        repository = "sftp:backup@${host}:${config.networking.hostName}-rustfs-backup";
        inherit (hostBackup) passwordFile;
        inherit (hostBackup) initialize;
        inherit (hostBackup) extraOptions;
        inherit (hostBackup) pruneOpts;
        inherit (hostBackup) timerConfig;

        paths = [ "/var/lib/rustfs/data" ];

        backupPrepareCommand = ''
          systemctl stop rustfs.service
        '';

        backupCleanupCommand = ''
          systemctl start rustfs.service
        '';
      }
    );
  };
}
