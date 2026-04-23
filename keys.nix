let
  users = {
    dsqr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfvrJELCv6dQp2VoceeVrtx1e0mnVo2FgNgu9o98BtF me@dsqr.dev";
  };

  hosts = {
    beacon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCE5HjvopVhcx9Wib2SKQjIJWAkqsIQ+yWuXKKp0fst root@beacon";
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICf3SJzSds97qSOnaihrdcQk0GRIkeCY2PSobD+Rj4Zt root@gateway";
    k8s-master-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBozJ9oeMgl6KxcXZp+pcdEM9nfIiM+FVUixKxMeCia root@k8s-master-01";
    k8s-node-01 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMnEJyDzHVE/xRBU1tnwvTygI7jF2X9IMqqoUxfQPr1 root@k8s-node-01";
    k8s-node-02 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7GdKgSr1RZ1QQUuSWUiDc7DjdoSGkTODEinZV7HsFU root@k8s-node-02";
    khaos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICiSoBRJAqEH2DGnNLSmDF6PFKZevfntV2FXaPa9EC8 root@khaos";
    hoo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjUr1zcIllfcXSkgx2Uh2YqLNRJUgygfR8cUdW7o1zE root@hoo";
    mail-vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrwjdEz7mbg7E7BO6FqNG4S6eAcx73ktPhniXDwTGBu root@mail-vps";
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
