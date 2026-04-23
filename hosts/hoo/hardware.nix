{ lib, modulesPath, ... }:

let
  inherit (lib) mkDefault;
in

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ea282a8c-0c4c-4333-a41e-41aa6b03661e";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";
}
