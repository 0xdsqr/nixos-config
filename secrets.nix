let
  inherit (import ./keys.nix)
    admins
    beacon
    all
    gateway
    k8s-master-01
    k8s-node-01
    k8s-node-02
    khaos
    ;
in
{
  "hosts/beacon/password.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana/secret-key.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana/password.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana/db-password.age".publicKeys = [ beacon ] ++ admins;

  "hosts/gateway/cloudflared/credentials.json.age".publicKeys = [ gateway ] ++ admins;
  "hosts/gateway/password.age".publicKeys = [ gateway ] ++ admins;

  "hosts/k8s-master-01/password.age".publicKeys = [ k8s-master-01 ] ++ admins;
  "hosts/k8s-node-01/password.age".publicKeys = [ k8s-node-01 ] ++ admins;
  "hosts/k8s-node-02/password.age".publicKeys = [ k8s-node-02 ] ++ admins;

  "hosts/khaos/password.age".publicKeys = [ khaos ] ++ admins;
  "hosts/khaos/rustfs/access-key.age".publicKeys = [ khaos ] ++ admins;
  "hosts/khaos/rustfs/secret-key.age".publicKeys = [ khaos ] ++ admins;

  "hosts/beacon/restic-password.age".publicKeys = all;
  "hosts/khaos/restic-password.age".publicKeys = all;
}
