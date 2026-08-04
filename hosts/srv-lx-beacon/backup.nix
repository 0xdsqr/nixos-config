{ config, lib, ... }:
let
  inherit (lib.attrsets) genAttrs;
in
{
  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [
      "/var/lib/grafana"
      "/var/lib/loki"
      "/var/lib/mimir"
      "/var/lib/prometheus2"
      "/var/lib/pyroscope"
      "/var/lib/tempo"
    ];

    backupPrepareCommand = ''
      systemctl stop grafana.service loki.service mimir.service prometheus.service pyroscope.service tempo.service
    '';

    backupCleanupCommand = ''
      systemctl start mimir.service loki.service tempo.service pyroscope.service prometheus.service grafana.service
    '';
  });
}
