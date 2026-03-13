{
  inputs,
  lib,
  pkgs,
  ...
}:
let
in
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "psql-datastore";
  };

  environment.systemPackages = with pkgs; [ ];

  system.stateVersion = "25.05";
}
