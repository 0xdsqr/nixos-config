{
  config,
  lib,
  pkgs,
  ...
}:
{
  # boot loader configuration - manages system startup and kernel loading
  # using grub because proxmox virtual machines present as traditional bios
  # systems (not UEFI), so grub handles the master boot record booting reliably
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ]; # single-disk Proxmox VM
}
