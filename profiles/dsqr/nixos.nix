{
  hostMeta ? null,
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

    restic = {
      hosts = mkDefault [ ];
      receiverHosts = mkDefault [ "srv-lx-backup" ];
      authorizedKeys = mkDefault keys.all;
      hostPublicKeys.srv-lx-backup = mkDefault keys.hosts.srv-lx-backup;
      passwordAgeFile = mkDefault (existingHostSecret "restic.password.age");
    };
  };
}
