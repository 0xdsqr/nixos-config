{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "cellar";
    staticIP = {
      enable = true;
      address = "192.168.50.35";
    };
  };

  environment.systemPackages = with pkgs; [ ];

  system.stateVersion = "25.05";
}
