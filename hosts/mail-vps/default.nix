{
  collectNix,
  ...
}:
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
        boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };

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
      enable = false;
      authKeyAgeFile = ./tailscale.auth-key.age;
    };
    alloy.enable = false;

    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };
  };

  services.openssh.openFirewall = true;

  services.qemuGuest.enable = true;

  boot.kernelParams = [ "console=ttyS0,115200" ];
  boot.loader.grub.enable = true;

  system.stateVersion = "25.11";
}
