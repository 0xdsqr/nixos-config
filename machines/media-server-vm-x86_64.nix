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

    # Core media services (all enabled by default)
    jellyfin.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
    lidarr.enable = true;
    bazarr.enable = true;
    qbittorrent.enable = true;

    # Home automation (disabled for now)
    homeAssistant.enable = false;
    mosquitto.enable = false;
    frigate.enable = false;
  };

  system.stateVersion = "25.05";
}
