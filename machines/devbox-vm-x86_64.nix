{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-nix inputs)
    (inputs.self.nixosModules.dsqr-proxmox inputs)
  ];

  # Our default non-specialised desktop environment.
  services.xserver = lib.mkIf (config.specialisation != { }) {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };

  # Configure eevee module
  eevee = (import ../users/eevee-defaults.nix) // {
    nixos.exclude_packages = [ ]; # Add packages to exclude if needed
  };

  networking = {
    hostName = "dojo";
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
