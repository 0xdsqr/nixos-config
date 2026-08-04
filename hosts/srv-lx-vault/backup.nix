{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) genAttrs;
  snapshotDirectory = "/var/lib/backup-staging/vault";
  roleId = "87b5b960-f1e8-4cc0-8d23-9ba8fcb07611";
in
{
  age.secrets.vaultRaftSnapshotSecretId = {
    file = ./vault-raft-snapshot.secret-id.age;
    mode = "0400";
  };

  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ snapshotDirectory ];

    backupPrepareCommand = ''
      install -d -o root -g root -m 0700 ${snapshotDirectory}
      rm -f ${snapshotDirectory}/snapshot.snap

      token="$(${pkgs.jq}/bin/jq -cn \
        --arg role_id ${lib.escapeShellArg roleId} \
        --rawfile secret_id ${config.age.secrets.vaultRaftSnapshotSecretId.path} \
        '{role_id: $role_id, secret_id: ($secret_id | rtrimstr("\n"))}' \
        | ${pkgs.curl}/bin/curl --silent --show-error --fail-with-body \
          --request POST \
          --header 'Content-Type: application/json' \
          --data-binary @- \
          https://vault.service.home.arpa:8200/v1/auth/approle/login \
        | ${pkgs.jq}/bin/jq --exit-status --raw-output '.auth.client_token')"

      VAULT_ADDR=https://vault.service.home.arpa:8200 \
        VAULT_TOKEN="$token" \
        ${pkgs.vault-bin}/bin/vault operator raft snapshot save ${snapshotDirectory}/snapshot.snap

      chmod 0600 ${snapshotDirectory}/snapshot.snap
      test -s ${snapshotDirectory}/snapshot.snap
      unset token
    '';

    backupCleanupCommand = ''
      rm -rf ${snapshotDirectory}
    '';
  });
}
