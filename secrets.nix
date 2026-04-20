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
    mimizuku
    ;
in
{
  "hosts/beacon/host.password.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana.secret-key.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana.admin.password.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana.database.password.age".publicKeys = [ beacon ] ++ admins;

  "hosts/gateway/tunnel.credentials.age".publicKeys = [ gateway ] ++ admins;
  "hosts/gateway/host.password.age".publicKeys = [ gateway ] ++ admins;

  "hosts/k8s-master-01/host.password.age".publicKeys = [ k8s-master-01 ] ++ admins;
  "hosts/k8s-node-01/host.password.age".publicKeys = [ k8s-node-01 ] ++ admins;
  "hosts/k8s-node-02/host.password.age".publicKeys = [ k8s-node-02 ] ++ admins;
  "hosts/mimizuku/host.password.age".publicKeys = [ mimizuku ] ++ admins;
  "hosts/mimizuku/openclaw/openclaw.env.age".publicKeys = [ mimizuku ] ++ admins;

  "hosts/khaos/host.password.age".publicKeys = [ khaos ] ++ admins;
  "hosts/khaos/rustfs.access-key.age".publicKeys = [ khaos ] ++ admins;
  "hosts/khaos/rustfs.secret-key.age".publicKeys = [ khaos ] ++ admins;

  "hosts/beacon/restic.password.age".publicKeys = all;
  "hosts/khaos/restic.password.age".publicKeys = all;
}
