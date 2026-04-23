{
  collectNix,
  keys,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  hasPasswordAgeFile = builtins.pathExists ./host.password.age;
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
    tailscale.enable = false;
    alloy.enable = false;

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

  services.openssh.openFirewall = true;
  services.openssh.settings.PermitRootLogin =
    lib.mkForce (if hasPasswordAgeFile then "no" else "prohibit-password");

  services.qemuGuest.enable = true;

  boot.kernelParams = [ "console=ttyS0,115200" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
