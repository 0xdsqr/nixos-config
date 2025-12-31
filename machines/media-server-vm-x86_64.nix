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
      9696  # Prowlarr
      7878  # Radarr
      8080  # qBittorrent web UI
      8989  # Sonarr
      8686  # Lidarr
      6767  # Bazarr
      8096  # Jellyfin
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

  # Prowlarr - Indexer manager (port 9696)
  services.prowlarr = {
    enable = true;
  };

  # Radarr - Movies (port 7878)
  services.radarr = {
    enable = true;
    group = "media";
  };

  # qBittorrent - Download client (port 8080)
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "media";
    home = "/var/lib/qbittorrent";
    createHome = true;
  };

  # Pre-create qBittorrent config with known password
  # Password: "adminadmin" (change in UI after first login)
  systemd.tmpfiles.settings."qbittorrent" = {
    "/var/lib/qbittorrent/.config/qBittorrent".d = {
      user = "qbittorrent";
      group = "media";
      mode = "0755";
    };
  };

  environment.etc."qbittorrent-init-config.conf".text = ''
    [Preferences]
    WebUI\Username=admin
    WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gez9bujMCFnbr4CaLrNcFhEMAAZpA6kduOQbvCZq5JCcfPzTEzUEg==)"
    
    [BitTorrent]
    Session\DefaultSavePath=/data/downloads/complete
    Session\TempPath=/data/downloads/incomplete
    Session\TempPathEnabled=true
  '';

  systemd.services.qbittorrent = {
    description = "qBittorrent-nox";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      CONFIG_DIR="/var/lib/qbittorrent/.config/qBittorrent"
      CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"
      if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$CONFIG_DIR"
        cp /etc/qbittorrent-init-config.conf "$CONFIG_FILE"
        chown -R qbittorrent:media "$CONFIG_DIR"
      fi
    '';
    serviceConfig = {
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080 --confirm-legal-notice";
      User = "qbittorrent";
      Group = "media";
      StateDirectory = "qbittorrent";
      Restart = "on-failure";
    };
  };

  # Sonarr - TV Shows (port 8989)
  services.sonarr = {
    enable = true;
    group = "media";
  };

  # Lidarr - Music (port 8686)
  services.lidarr = {
    enable = true;
    group = "media";
  };

  # Bazarr - Subtitles (port 6767)
  services.bazarr = {
    enable = true;
    group = "media";
  };

  # Jellyfin - Media server (port 8096)
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  system.stateVersion = "25.05";
}