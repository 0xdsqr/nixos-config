let
  keys = import ./profiles/dsqr/keys.nix;
  inherit (keys) hosts;
  inherit (keys.groups) admins all;

  forHost = name: [ hosts.${name} ] ++ admins;

  forAllHosts = all;

  mkSecretsForHost =
    hostName: secretFiles:
    builtins.listToAttrs (
      builtins.map (path: {
        name = path;
        value.publicKeys = forHost hostName;
      }) secretFiles
    );

  mkSharedSecrets =
    secretFiles:
    builtins.listToAttrs (
      builtins.map (path: {
        name = path;
        value.publicKeys = forAllHosts;
      }) secretFiles
    );

in
mkSecretsForHost "srv-lx-beacon" [
  "hosts/srv-lx-beacon/host.password.age"
  "hosts/srv-lx-beacon/grafana.secret-key.age"
  "hosts/srv-lx-beacon/grafana.admin.password.age"
  "hosts/srv-lx-beacon/grafana.database.password.age"
  "hosts/srv-lx-beacon/tailscale.auth-key.age"
]
// mkSecretsForHost "srv-lx-gateway" [
  "hosts/srv-lx-gateway/cloudflared.token.age"
  "hosts/srv-lx-gateway/host.password.age"
  "hosts/srv-lx-gateway/tailscale.auth-key.age"
]
// mkSecretsForHost "srv-lx-k8s-master-01" [
  "hosts/srv-lx-k8s-master-01/host.password.age"
  "hosts/srv-lx-k8s-master-01/tailscale.auth-key.age"
]
// mkSecretsForHost "srv-lx-k8s-node-01" [
  "hosts/srv-lx-k8s-node-01/host.password.age"
  "hosts/srv-lx-k8s-node-01/tailscale.auth-key.age"
]
// mkSecretsForHost "srv-lx-k8s-node-02" [
  "hosts/srv-lx-k8s-node-02/host.password.age"
  "hosts/srv-lx-k8s-node-02/tailscale.auth-key.age"
]
// mkSecretsForHost "srv-lx-mailbox" [
  "hosts/srv-lx-mailbox/host.password.age"
  "hosts/srv-lx-mailbox/tailscale.auth-key.age"
  "hosts/srv-lx-mailbox/cloudflare-acme.env.age"
  "hosts/srv-lx-mailbox/stalwart-admin.secret.age"
  "hosts/srv-lx-mailbox/stalwart-me.password.age"
  "hosts/srv-lx-mailbox/stalwart-admin.password.age"
  "hosts/srv-lx-mailbox/stalwart-dkim-rsa.key.age"
  "hosts/srv-lx-mailbox/stalwart-dkim-ed25519.key.age"
]
// mkSecretsForHost "srv-lx-khaos" [
  "hosts/srv-lx-khaos/host.password.age"
  "hosts/srv-lx-khaos/redis.password.age"
  "hosts/srv-lx-khaos/rustfs.access-key.age"
  "hosts/srv-lx-khaos/rustfs.secret-key.age"
  "hosts/srv-lx-khaos/tailscale.auth-key.age"
  "hosts/srv-lx-khaos/temporal/postgres.env.age"
  "hosts/srv-lx-khaos/vault-listener-pki.env.age"
]
// mkSecretsForHost "srv-lx-knox" [
  "hosts/srv-lx-knox/listener-pki.secret-id.age"
  "hosts/srv-lx-knox/postgresql-replication.pgpass.age"
  "hosts/srv-lx-knox/tailscale.auth-key.age"
]
// mkSharedSecrets [
  "hosts/srv-lx-beacon/restic.password.age"
  "hosts/srv-lx-khaos/restic.password.age"
]
// {
  "hosts/dev-mbp-personal/tailscale.auth-key.age".publicKeys = admins;
  "hosts/dev-mbp-stablecore/git.config.inc.age".publicKeys = admins;
}
