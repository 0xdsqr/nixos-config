let
  users = {
    dsqr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfvrJELCv6dQp2VoceeVrtx1e0mnVo2FgNgu9o98BtF me@dsqr.dev";
  };

  hosts = {
    beacon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCE5HjvopVhcx9Wib2SKQjIJWAkqsIQ+yWuXKKp0fst root@beacon";
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICf3SJzSds97qSOnaihrdcQk0GRIkeCY2PSobD+Rj4Zt root@gateway";
    k8s-master-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBozJ9oeMgl6KxcXZp+pcdEM9nfIiM+FVUixKxMeCia root@nixos-minimal-dsqr-server";
    k8s-node-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMnEJyDzHVE/xRBU1tnwvTygI7jF2X9IMqqoUxfQPr1 root@nixos-minimal-dsqr-server";
    k8s-node-02 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7GdKgSr1RZ1QQUuSWUiDc7DjdoSGkTODEinZV7HsFU root@nixos-minimal-dsqr-server";
    khaos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICiSoBRJAqEH2DGnNLSmDF6PFKZevfntV2FXaPa9EC8 root@khaos";
    mimizuku = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjUr1zcIllfcXSkgx2Uh2YqLNRJUgygfR8cUdW7o1zE root@nixos-minimal-dsqr-server";
  };

  groups = rec {
    admins = [ users.dsqr ];
    allHosts = builtins.attrValues hosts;
    all = admins ++ allHosts;
  };
in
users
// hosts
// {
  inherit users hosts groups;
  inherit (groups) admins all allHosts;
}
