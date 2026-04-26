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
    sshHost = "10.10.30.104";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      removeAttrs nixosModules [
        "containers"
        "postgresql"
        "redis"
        "restic"
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
          "window-manager"
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
      {
        networking.hostName = "srv-lx-k8s-master-01";
        hardware.report = ./srv-lx-k8s-master-01.report.json;

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

        dsqr.nixos.alloy = {
          role = "k8s-control-plane";

          kubernetes.kubeconfigFile = "/etc/kubernetes/admin.conf";
        };

        swapDevices = [ ];

        networking = {
          domain = "dsqr.dev";

          firewall.allowedTCPPorts = [
            22
            6443
            2379
            2380
            10250
            10257
            10259
          ];
        };

        system.stateVersion = "25.05";
      }
    ];
in
{
  flake.hostDefinitions.srv-lx-k8s-master-01 = hostMeta;

  flake.nixosConfigurations.srv-lx-k8s-master-01 = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-k8s-master-01";
  };
}
