{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) genAttrs;
  snapshotDirectory = "/var/lib/backup-staging/etcd";
in
{
  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ snapshotDirectory ];

    backupPrepareCommand = ''
      install -d -o root -g root -m 0700 ${snapshotDirectory}
      rm -f ${snapshotDirectory}/snapshot.db
      ETCDCTL_API=3 ${pkgs.etcd}/bin/etcdctl snapshot save ${snapshotDirectory}/snapshot.db \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
        --key=/etc/kubernetes/pki/etcd/healthcheck-client.key
      ETCDCTL_API=3 ${pkgs.etcd}/bin/etcdctl snapshot status ${snapshotDirectory}/snapshot.db
    '';

    backupCleanupCommand = ''
      rm -rf ${snapshotDirectory}
    '';
  });
}
