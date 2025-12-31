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
    hostName = "media-server";
    firewall.allowedTCPPorts = [
      9696 # Prowlarr
      7878 # Radarr
      8080 # qBittorrent web UI
      # 8989  # Sonarr
      # 8686  # Lidarr
      # 8787  # Readarr
      # 6767  # Bazarr
      # 8096  # Jellyfin
    ];
  };

  environment.systemPackages = with pkgs; [ ];

  # Create a shared group for media permissions
  users.groups.media = { };

  # Shared media directories
  systemd.tmpfiles.rules = [
    "d /data/media 0775 root media -"
    "d /data/media/movies 0775 root media -"
    "d /data/media/tv 0775 root media -"
    "d /data/media/music 0775 root media -"
    "d /data/downloads 0775 root media -"
    "d /data/downloads/complete 0775 root media -"
    "d /data/downloads/incomplete 0775 root media -"
  ];

  # Runs on port 9696 by default
  services.prowlarr = {
    enable = true;
  };

  # Runs on port 7878 by default
  services.radarr = {
    enable = true;
    group = "media";
  };

  # qBittorrent - Web UI on port 8080
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/qbittorrent";
    createHome = true;
  };

  systemd.services.qbittorrent = {
    description = "qBittorrent-nox";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080";
      User = "qbittorrent";
      Group = "media";
      StateDirectory = "qbittorrent";
      Restart = "on-failure";
    };
  };

  system.stateVersion = "25.05";
}
