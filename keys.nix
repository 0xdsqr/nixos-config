let
  users = {
    dsqr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfvrJELCv6dQp2VoceeVrtx1e0mnVo2FgNgu9o98BtF me@dsqr.dev";
  };

  hosts = {
    srv-lx-beacon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCE5HjvopVhcx9Wib2SKQjIJWAkqsIQ+yWuXKKp0fst root@srv-lx-beacon";
    srv-lx-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICf3SJzSds97qSOnaihrdcQk0GRIkeCY2PSobD+Rj4Zt root@srv-lx-gateway";
    srv-lx-k8s-master-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBozJ9oeMgl6KxcXZp+pcdEM9nfIiM+FVUixKxMeCia root@srv-lx-k8s-master-01";
    srv-lx-k8s-node-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMnEJyDzHVE/xRBU1tnwvTygI7jF2X9IMqqoUxfQPr1 root@srv-lx-k8s-node-01";
    srv-lx-k8s-node-02 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7GdKgSr1RZ1QQUuSWUiDc7DjdoSGkTODEinZV7HsFU root@srv-lx-k8s-node-02";
    srv-lx-khaos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICiSoBRJAqEH2DGnNLSmDF6PFKZevfntV2FXaPa9EC8 root@srv-lx-khaos";
    srv-lx-hoo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjUr1zcIllfcXSkgx2Uh2YqLNRJUgygfR8cUdW7o1zE root@srv-lx-hoo";
    srv-lx-mailbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrwjdEz7mbg7E7BO6FqNG4S6eAcx73ktPhniXDwTGBu root@srv-lx-mailbox";
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
