{ self, inputs, ... }:
let
  inherit (self.lib)
    commonModules
    homeModules
    nixLib
    nixosModules
    ;
  inherit (nixLib.attrsets) attrValues;
  inherit (nixLib.lists) singleton;

  hostName = "srv-lx-beacon";

  modules =
    attrValues commonModules
    ++ attrValues nixosModules
    ++ [
      ../../profiles/dsqr/common.nix
      ../../profiles/dsqr/nixos.nix
    ]
    ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.102";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { ... }: {
        imports =
          modules
          ++ [ ../../profiles/observability/nixos.nix ]
          ++ self.lib.collectNix {
            path = ./.;
            exclude = path: path == ./default.nix;
          };

        networking.hostName = hostName;
        hardware.report = ./srv-lx-beacon.report.json;

        dsqr.nixos = {
          fonts.enable = true;
          openssh.enable = true;
          proxmox.enable = true;
          restic = {
            enable = true;
            hosts = [ "srv-lx-backup" ];
            passwordAgeFile = ./restic.password.age;
          };
          tailscale.enable = true;
          user.enable = true;
        };

        home-manager.users.dsqr.dsqr.home = {
          aws.enable = false;
          bat.enable = false;
          claudeCode.enable = false;
          codex.enable = false;
          difftastic.enable = false;
          hushlogin.enable = false;
          opencode.enable = false;

          packages = {
            containers.enable = false;
            databases.enable = false;
            debugging.enable = false;
            kubernetes.enable = false;
            media.enable = false;
            node.enable = false;
            signing.enable = false;
          };

          desktop = {
            browsers.helium.enable = false;
          };
        };

        networking.firewall.extraInputRules = ''
          ip saddr { 10.10.30.0/24, 10.10.60.100/32 } tcp dport { 8000, 9090, 3100, 4040, 4317, 4318, 9009 } accept
          ip saddr 10.10.10.1/32 tcp dport 1514 accept
          iifname "tailscale0" ip saddr 100.125.141.48/32 tcp dport 1515 accept
        '';
        networking.dhcpcd.wait = "ipv4";
        networking.nftables.enable = true;

        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.srv-lx-beacon-installer = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = "srv-lx-beacon-installer";

    modules = singleton (
      { ... }: {
        imports = installerModules;

        dsqr.nixos.installer = {
          enable = true;
          hostName = "srv-lx-beacon-installer";
          targetHostName = hostName;
        };

        home-manager.users.dsqr.dsqr.home = {
          claudeCode.enable = false;
          opencode.enable = false;
        };

        system.stateVersion = "25.05";
      }
    );
  };
}
