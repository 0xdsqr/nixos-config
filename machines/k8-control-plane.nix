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
    hostName = "k8-control-plane";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
    ];
  };


  system.stateVersion = "25.05";
}
