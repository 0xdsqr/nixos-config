{ pkgs, ... }:
{
  virtualisation.containers.enable = true;
  virtualisation = {
    docker.enable = true;
    podman = {
      enable = true;
      dockerCompat = false; # Keep false since docker is enabled
      dockerSocket.enable = false;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
