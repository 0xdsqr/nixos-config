{
  hostMeta ? null,
  hostName,
  lib,
  ...
}:
let
  inherit (lib.modules) mkDefault;

  keys = import ./keys.nix;

  existingHostSecret =
    name:
    let
      path = if hostMeta == null then null else hostMeta.path + "/${name}";
    in
    if path != null && builtins.pathExists path then path else null;
in
{
  dsqr.nixos = {
    user = {
      name = mkDefault "dsqr";
      home = mkDefault "/home/dsqr";
      description = mkDefault "its me dave";
      extraGroups = mkDefault [
        "wheel"
        "networkmanager"
        "docker"
        "lxd"
      ];
      authorizedKeys = mkDefault keys.admins;
      passwordAgeFile = mkDefault (existingHostSecret "host.password.age");
    };

    tailscale.authKeyAgeFile = mkDefault (existingHostSecret "tailscale.auth-key.age");

    alloy = {
      environment = mkDefault "homelab";
      remoteWriteUrl = mkDefault (
        if hostName == "srv-lx-beacon" then "http://127.0.0.1:9090/api/v1/write" else "http://10.10.30.102:9090/api/v1/write"
      );

      kubernetes.cluster = mkDefault "hub-a";

      loki.writeUrl = mkDefault (
        if hostName == "srv-lx-beacon" then
          "http://127.0.0.1:3100/loki/api/v1/push"
        else
          "http://10.10.30.102:3100/loki/api/v1/push"
      );
    };

    restic = {
      hosts = mkDefault (if hostName == "srv-lx-khaos" then [ "srv-lx-beacon" ] else [ ]);
      receiverHosts = mkDefault [ "srv-lx-beacon" ];
      authorizedKeys = mkDefault keys.all;
      passwordAgeFile = mkDefault (existingHostSecret "restic.password.age");
    };
  };
}
