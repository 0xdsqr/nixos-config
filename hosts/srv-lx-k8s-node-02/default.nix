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
    sshHost = "10.10.30.103";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues (
      removeAttrs nixosModules [
        "containers"
        "monitoring-alloy-prometheus"
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
        networking = {
          hostName = "srv-lx-k8s-node-02";
          domain = "dsqr.dev";
        };

        hardware.report = ./srv-lx-k8s-node-02.report.json;

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

        dsqr.nixos.alloy.role = "k8s-worker";

        swapDevices = [ ];

        system.stateVersion = "25.05";
      }
    ];
in
{
  flake.hostDefinitions.srv-lx-k8s-node-02 = hostMeta;

  flake.nixosConfigurations.srv-lx-k8s-node-02 = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-k8s-node-02";
  };
}
