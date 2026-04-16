let
  keys = {
    dsqr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfvrJELCv6dQp2VoceeVrtx1e0mnVo2FgNgu9o98BtF me@dsqr.dev";
    beacon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCE5HjvopVhcx9Wib2SKQjIJWAkqsIQ+yWuXKKp0fst root@beacon";
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICf3SJzSds97qSOnaihrdcQk0GRIkeCY2PSobD+Rj4Zt root@gateway";
    khaos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICiSoBRJAqEH2DGnNLSmDF6PFKZevfntV2FXaPa9EC8 root@khaos";
  };
in
keys
// {
  admins = [ keys.dsqr ];
  all = builtins.attrValues keys;
}
