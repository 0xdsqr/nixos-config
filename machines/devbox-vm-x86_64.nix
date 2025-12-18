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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # Our default non-specialised desktop environment.
  services.xserver = lib.mkIf (config.specialisation != { }) {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };

  # Configure eevee module
  eevee = {
    full_name = "0xdsqr";
    email_address = "dave.dennis@gs.com";
    theme = "tokyo-night";
    nixos.exclude_packages = [ ]; # Add packages to exclude if needed
  };

  networking = {
    hostName = "dojo";
    domain = "dsqr.dev";
  };

  system.stateVersion = "25.05";
}
