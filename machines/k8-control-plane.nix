{
  inputs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-k8 inputs)
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  dsqrK8.hostName = "k8-control-plane";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
    ];
  };

  system.stateVersion = "25.05";
}
