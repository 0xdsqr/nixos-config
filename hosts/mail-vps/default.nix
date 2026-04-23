{
  collectNix,
  keys,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  hasPasswordAgeFile = builtins.pathExists ./host.password.age;
  hasTailscaleAuthKey = builtins.pathExists ./tailscale.auth-key.age;
in
{
  imports = collectNix {
    dir = ./.;
    ignoredFiles = [
      ./default.nix
      ./meta.nix
    ];
  };

  networking.hostName = "mail-vps";

  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          end = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          end = "-0";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  dsqr.nixos = {
    tailscale = {
      enable = hasTailscaleAuthKey;
      authKeyAgeFile = if hasTailscaleAuthKey then ./tailscale.auth-key.age else null;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--advertise-tags=tag:cloud,tag:hetzner,tag:mail" ];
    };

    user = {
      enable = hasPasswordAgeFile;
      passwordAgeFile = if hasPasswordAgeFile then ./host.password.age else null;
      serverAdmin.enable = true;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = keys.admins;

  users.users.dsqr = mkIf (!hasPasswordAgeFile) {
    isNormalUser = true;
    home = "/home/dsqr";
    description = "its me dave";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = keys.admins;
  };

  services.openssh.settings.PermitRootLogin =
    lib.mkForce (if hasPasswordAgeFile then "no" else "prohibit-password");

  services.qemuGuest.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
