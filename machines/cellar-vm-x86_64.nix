{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.self.nixosModules.rustfs
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "cellar";
    staticIP = {
      enable = true;
      address = "192.168.50.35";
    };
    firewall.allowedTCPPorts = [
      9000 # RustFS S3 API
      9001 # RustFS Console
    ];
  };

  # RustFS S3-compatible object storage
  services.dsqr-rustfs = {
    enable = true;
    package = inputs.rustfs.packages.${pkgs.system}.default;
    address = "0.0.0.0";
    consoleAddress = "0.0.0.0";
    # TODO: Use SOPS for credentials in production
    # rootCredentialsFile = config.sops.secrets."rustfs/credentials".path;
  };

  system.stateVersion = "25.05";
}
