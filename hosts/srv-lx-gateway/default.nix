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
    sshHost = "10.10.60.100";
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
      ./alloy-cloudflared.nix
      ./cloudflared.nix
      {
        networking.hostName = "srv-lx-gateway";
        hardware.report = ./srv-lx-gateway.report.json;

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

        swapDevices = [ ];

        system.stateVersion = "25.05";
      }
    ];
in
{
  flake.hostDefinitions.srv-lx-gateway = hostMeta;

  flake.nixosConfigurations.srv-lx-gateway = self.lib.nixosSystem {
    inherit hostMeta modules;
    hostName = "srv-lx-gateway";
  };
}
