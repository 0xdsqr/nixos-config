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

  hostName = "srv-lx-gateway";

  modules =
    attrValues commonModules ++ attrValues nixosModules ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.60.100";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { ... }:
      {
        imports = modules ++ [
          ./cloudflared.nix
          ./disk.nix
        ];

        networking.hostName = hostName;
        hardware.report = ./srv-lx-gateway.report.json;

        dsqr.nixos = {
          alloy = {
            enable = true;
            loki.enable = true;
          };

          fonts.enable = true;
          openssh.enable = true;
          proxmox.enable = true;
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
          pi.enable = false;

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

        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.srv-lx-gateway-installer = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = "srv-lx-gateway-installer";

    modules = singleton (
      { ... }:
      {
        imports = installerModules;

        dsqr.nixos.installer = {
          enable = true;
          hostName = "srv-lx-gateway-installer";
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
