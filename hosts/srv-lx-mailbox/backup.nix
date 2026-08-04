{ config, lib, ... }:
let
  inherit (lib.attrsets) genAttrs;
in
{
  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ config.services.stalwart.dataDir ];

    backupPrepareCommand = ''
      systemctl stop stalwart.service
    '';

    backupCleanupCommand = ''
      systemctl start stalwart.service
    '';
  });
}
