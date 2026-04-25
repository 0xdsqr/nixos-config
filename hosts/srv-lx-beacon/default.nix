{ self, ... }:
let
  inherit (self.lib)
    commonModules
    homeModules
    nixLib
    nixosModules
    ;
  inherit (nixLib.attrsets) attrValues removeAttrs;
  inherit (nixLib.lists) singleton;

  hostMeta = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.102";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      removeAttrs nixosModules [
        "containers"
        "kubeadm"
        "monitoring-alloy-prometheus"
        "postgresql"
        "redis"
        "rustfs"
      ]
    )
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        removeAttrs homeModules [
          "aws"
          "bat"
          "cinny"
          "claude-code"
          "codex"
          "darwin-wm"
          "difftastic"
          "discord"
          "exo"
          "hammerspoon"
          "hushlogin"
          "ollama"
          "packages-containers"
          "packages-databases"
          "packages-debugging"
          "packages-kubernetes"
          "packages-media"
          "packages-node"
          "packages-signing"
          "opencode"
          "pi"
          "signal"
          "theme"
          "thunderbird"
          "web-browser"
        ]
      )
    )
    ++ [
      ./alloy-opnsense.nix
      ./grafana.nix
      ./loki.nix
      ./prometheus.nix
      {
        networking.hostName = "srv-lx-beacon";
        hardware.report = ./srv-lx-beacon.report.json;

        boot.loader.grub = {
          enable = true;
          devices = nixLib.mkForce [ "/dev/sda" ];
        };

        disko.devices.disk.main = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02";
                priority = 1;
              };

              root = {
                end = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        services.restic.passwordAgeFile = ./restic.password.age;
        swapDevices = [ ];

        networking.firewall.allowedTCPPorts = [
          8000
          9090
          3100
          1514
        ];

        system.stateVersion = "25.05";
      }
    ];
in
{
  flake.hostDefinitions.srv-lx-beacon = hostMeta;

  flake.nixosConfigurations.srv-lx-beacon = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-beacon";
  };
}
