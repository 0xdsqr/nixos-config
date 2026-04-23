let
  keys = import ./keys.nix;
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
mkSecretsForHost "beacon" [
  "hosts/beacon/host.password.age"
  "hosts/beacon/grafana.secret-key.age"
  "hosts/beacon/grafana.admin.password.age"
  "hosts/beacon/grafana.database.password.age"
]
// mkSecretsForHost "gateway" [
  "hosts/gateway/cloudflared.token.age"
  "hosts/gateway/host.password.age"
]
// mkSecretsForHost "k8s-master-01" [ "hosts/k8s-master-01/host.password.age" ]
// mkSecretsForHost "k8s-node-01" [ "hosts/k8s-node-01/host.password.age" ]
// mkSecretsForHost "k8s-node-02" [ "hosts/k8s-node-02/host.password.age" ]
// mkSecretsForHost "hoo" [
  "hosts/hoo/host.password.age"
  "hosts/hoo/openclaw/openclaw.env.age"
  "hosts/hoo/tailscale.auth-key.age"
]
// mkSecretsForHost "khaos" [
  "hosts/khaos/host.password.age"
  "hosts/khaos/redis.password.age"
  "hosts/khaos/rustfs.access-key.age"
  "hosts/khaos/rustfs.secret-key.age"
]
// mkSharedSecrets [
  "hosts/beacon/restic.password.age"
  "hosts/khaos/restic.password.age"
]
