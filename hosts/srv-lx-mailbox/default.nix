{ self, inputs, ... }:
let
  inherit (self.lib)
    commonModules
    homeModules
    nixLib
    nixosModules
    ;
  inherit (nixLib.attrsets) attrValues removeAttrs;
  inherit (nixLib.lists) singleton;
  inherit (nixLib.trivial) flip;

  hostMeta = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "178.156.204.203";
    system = "x86_64-linux";
  };

  modules =
    attrValues commonModules
    ++ attrValues nixosModules
    ++ singleton (
      self.lib.mkHomeManagerSharedModule (
        flip removeAttrs [
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
          "thunderbird"
          "web-browser"
        ] homeModules
      )
    );

  systemModules = modules ++ [
    ./stalwart.nix
    {
      networking.hostName = "srv-lx-mailbox";
      hardware.report = ./srv-lx-mailbox.report.json;

      dsqr.nixos = {
        fonts.enable = true;
        openssh.enable = true;
        tailscale.enable = true;
        user.enable = true;
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

            ESP = {
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            root = {
              end = "-0";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      services.tailscale = {
        useRoutingFeatures = "client";
        extraUpFlags = [ "--ssh" ];
      };

      services.openssh.openFirewall = true;

      boot.kernelParams = [ "console=ttyS0,115200" ];
      boot.loader.grub.enable = true;

      system.stateVersion = "25.11";
    }
  ];

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.srv-lx-mailbox = hostMeta;

  flake.nixosConfigurations.srv-lx-mailbox = self.lib.nixosSystem {
    hostName = "srv-lx-mailbox";
    inherit hostMeta;
    modules = singleton (
      { ... }:
      {
        imports = systemModules;
      }
    );
  };

  flake.nixosConfigurations.srv-lx-mailbox-installer = self.lib.nixosSystem {
    inherit hostMeta;
    hostName = "srv-lx-mailbox-installer";
    modules = singleton (
      { ... }:
      {
        imports = installerModules;

        dsqr.nixos.installer = {
          enable = true;
          hostName = "srv-lx-mailbox-installer";
          targetHostName = "srv-lx-mailbox";
        };

        system.stateVersion = "25.11";
      }
    );
  };
}
