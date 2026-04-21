{ config, lib, ... }:
let
  cfg = config.dsqr.nixos.containers;
in
lib.mkIf cfg.enable {
  virtualisation.containers.enable = true;

  virtualisation.docker.enable = cfg.docker.enable;
  virtualisation.podman = lib.mkIf cfg.podman.enable {
    enable = true;
    inherit (cfg.podman) dockerCompat;
    dockerSocket.enable = cfg.podman.dockerSocket.enable;
    defaultNetwork.settings.dns_enabled = cfg.podman.defaultNetwork.dnsEnabled;
  };
}
