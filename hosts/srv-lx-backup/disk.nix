{ lib, ... }: {
  boot.growPartition = true;

  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/sda" ];
  };

  fileSystems."/".autoResize = true;

  disko.devices.disk = {
    main = {
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

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    backup = {
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_backup-data";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var/lib/backup";
            mountOptions = [
              "noatime"
              "nodev"
              "nosuid"
            ];
          };
        };
      };
    };
  };

  fileSystems."/var/lib/backup".neededForBoot = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];
}
