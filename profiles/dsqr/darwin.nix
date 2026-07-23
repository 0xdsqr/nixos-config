{
  hostMeta ? null,
  lib,
  ...
}:
let
  inherit (lib.modules) mkDefault;

  existingHostSecret =
    name:
    let
      path = if hostMeta == null then null else hostMeta.path + "/${name}";
    in
    if path != null && builtins.pathExists path then path else null;
in
{
  dsqr.darwin = {
    personal.user = {
      enable = mkDefault true;
      name = mkDefault "dsqr";
      home = mkDefault "/Users/dsqr";
    };

    homebrew = {
      enable = mkDefault true;
      user = mkDefault "dsqr";
    };

    grafana = {
      alloy = {
        environment = mkDefault "homelab";
        prometheus.remoteWriteUrl = mkDefault "http://10.10.30.102:9090/api/v1/write";
      };

      loki.writeUrl = mkDefault "http://10.10.30.102:3100/loki/api/v1/push";
    };

    desktop = {
      lapdog.enable = mkDefault true;
      obsidian.enable = mkDefault true;
      tailscale.authKeyAgeFile = mkDefault (existingHostSecret "tailscale.auth-key.age");
    };
  };

  home-manager.users.dsqr.dsqr.home.desktop.obsidian = {
    enable = mkDefault true;
    profile = mkDefault "personal";
  };
}
