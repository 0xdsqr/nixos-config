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
  dsqr.darwin = {
    personal.user = {
      enable = mkDefault true;
      name = mkDefault "dsqr";
      home = mkDefault "/Users/dsqr";
      authorizedKeys = mkDefault keys.admins;
    };

    homebrew = {
      enable = mkDefault true;
      user = mkDefault "dsqr";
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
