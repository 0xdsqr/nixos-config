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
    inputs.media-server.nixosModules.media-server
  ];

  dsqr.proxmox.networking = {
    hostName = "media-server";
  };

  # Media server stack
  mediaServer = {
    enable = true;
    dataDir = "/data";

    # Home automation
    homeAssistant.enable = true;
    mosquitto.enable = true;
    frigate.enable = true;
  };

  system.stateVersion = "25.05";
}
