{
  config,
  lib,
  ...
}:
let
  cfg = config.dsqr.proxmox.networking;
in
{
  options.dsqr.proxmox.networking = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname for this machine";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "dsqr.dev";
      description = "The domain for this machine";
    };

    staticIP = {
      enable = lib.mkEnableOption "static IP configuration";

      address = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Static IP address (e.g., 192.168.50.35)";
      };

      prefixLength = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Network prefix length (e.g., 24 for /24)";
      };

      gateway = lib.mkOption {
        type = lib.types.str;
        default = "192.168.50.1";
        description = "Default gateway address";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "enp1s0";
        description = "Network interface name";
      };

      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        description = "DNS nameservers";
      };
    };

    firewall = {
      allowedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [
          22
          80
          443
        ];
        description = "TCP ports to open in the firewall";
      };
    };
  };

  config = {
    networking = {
      hostName = cfg.hostName;
      domain = cfg.domain;

      # Static IP or DHCP
      useDHCP = !cfg.staticIP.enable;

      interfaces = lib.mkIf cfg.staticIP.enable {
        ${cfg.staticIP.interface}.ipv4.addresses = [
          {
            address = cfg.staticIP.address;
            inherit (cfg.staticIP) prefixLength;
          }
        ];
      };

      defaultGateway = lib.mkIf cfg.staticIP.enable cfg.staticIP.gateway;
      nameservers = lib.mkIf cfg.staticIP.enable cfg.staticIP.nameservers;

      firewall.allowedTCPPorts = cfg.firewall.allowedTCPPorts;
    };
  };
}
