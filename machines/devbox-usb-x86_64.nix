{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-nix inputs)
  ];

  # Boot loader configuration for physical hardware
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
