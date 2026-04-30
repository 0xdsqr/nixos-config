{
  flake.nixosModules.containers =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) bool;
      cfg = config.dsqr.nixos.containers;
    in
    {
      options.dsqr.nixos.containers = {
        enable = mkEnableOption "Enable the shared container runtime baseline";

        docker.enable = mkOption {
          type = bool;
          default = true;
          description = "Enable Docker when the shared container runtime baseline is active.";
        };

        podman.enable = mkOption {
          type = bool;
          default = false;
          description = "Enable Podman when the shared container runtime baseline is active.";
        };

        podman.dockerCompat = mkOption {
          type = bool;
          default = true;
          description = "Expose the Docker-compatible Podman CLI shim when Podman is enabled.";
        };

        podman.dockerSocket.enable = mkOption {
          type = bool;
          default = true;
          description = "Expose the Docker-compatible Podman socket when Podman is enabled.";
        };

        podman.defaultNetwork.dnsEnabled = mkOption {
          type = bool;
          default = true;
          description = "Enable DNS in the default Podman network when Podman is enabled.";
        };
      };

      config = mkIf cfg.enable {
        virtualisation.containers.enable = true;

        virtualisation.docker.enable = cfg.docker.enable;
        virtualisation.podman = mkIf cfg.podman.enable {
          enable = true;
          inherit (cfg.podman) dockerCompat;
          dockerSocket.enable = cfg.podman.dockerSocket.enable;
          defaultNetwork.settings.dns_enabled = cfg.podman.defaultNetwork.dnsEnabled;
        };
      };
    };
}
