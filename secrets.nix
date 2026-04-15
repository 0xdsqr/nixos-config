let
  inherit (import ./keys.nix)
    admins
    beacon
    blue
    all
    gateway
    khaos
    ;
in
{
  "hosts/beacon/grafana/secret-key.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana/password.age".publicKeys = [ beacon ] ++ admins;
  "hosts/beacon/grafana/db-password.age".publicKeys = [ beacon ] ++ admins;

  "hosts/blue/cloudflare-acme.env.age".publicKeys = [ blue ] ++ admins;
  "hosts/blue/me-password.age".publicKeys = [ blue ] ++ admins;

  "hosts/gateway/cloudflared/credentials.json.age".publicKeys = [ gateway ] ++ admins;
  "hosts/khaos/rustfs/env.age".publicKeys = [ khaos ] ++ admins;

  "modules/nixos/restic/password.age".publicKeys = all;
}
