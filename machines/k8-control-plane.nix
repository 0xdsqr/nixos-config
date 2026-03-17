{
  inputs,
  ...
}:
{
  # The machine file chooses which modules participate in this host's final
  # config. Imported modules can declare options and contribute settings.
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-k8 inputs)
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  # This sets the custom option declared in `modules/k8/options.nix`.
  # The k8 base module reads it from `config.dsqrK8.hostName`.
  dsqrK8.hostName = "k8-control-plane";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
    ];
  };

  system.stateVersion = "25.05";
}
