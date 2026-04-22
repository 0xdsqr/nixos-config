{
  flake.nixosModules.containers =
    { config, lib, ... }:
    let
      inherit (lib) mkIf;
      cfg = config.dsqr.nixos.containers;
    in
    mkIf cfg.enable {
      virtualisation.containers.enable = true;

      virtualisation.docker.enable = cfg.docker.enable;
      virtualisation.podman = mkIf cfg.podman.enable {
        enable = true;
        inherit (cfg.podman) dockerCompat;
        dockerSocket.enable = cfg.podman.dockerSocket.enable;
        defaultNetwork.settings.dns_enabled = cfg.podman.defaultNetwork.dnsEnabled;
      };
    };
}
