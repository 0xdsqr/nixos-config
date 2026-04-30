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

  hostName = "srv-lx-hoo";

  modules =
    attrValues commonModules ++ attrValues nixosModules ++ singleton (self.lib.mkHomeManagerSharedModule homeModules);

  installerModules = modules ++ [ (inputs.nixpkgs + /nixos/modules/installer/cd-dvd/iso-image.nix) ];
in
{
  flake.hostDefinitions.${hostName} = self.lib.mkHostMeta {
    class = "nixos";
    path = ./.;
    sshHost = "10.10.30.108";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { config, ... }:
      {
        imports =
          modules
          ++ [
            inputs.hoo.nixosModules.hoo
            ./openclaw/default.nix
          ]
          ++ self.lib.collectNix {
            path = ./.;
            exclude = path: path == ./default.nix;
          };

        nixpkgs.overlays = singleton inputs.nix-openclaw.overlays.default;

        networking.hostName = hostName;
        hardware.report = ./srv-lx-hoo.report.json;

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

        age.secrets.githubDeployKey = {
          file = ./github.deploy-key.age;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        services.hoo.api-server = {
          enable = true;
          host = "0.0.0.0";
          port = 9321;
        };

        networking.firewall.allowedTCPPorts = [ 9321 ];

        home-manager.users.dsqr.dsqr.home = {
          aws.enable = false;
          bat.enable = false;
          codex.enable = false;
          difftastic.enable = false;
          hushlogin.enable = false;
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

        home-manager.users.dsqr.imports = [
          inputs.hoo.homeManagerModules.hoo
          { programs.hoo.enable = true; }
        ];

        programs.ssh.extraConfig = ''
          Host github.com
            User git
            IdentityFile ${config.age.secrets.githubDeployKey.path}
            IdentitiesOnly yes
            StrictHostKeyChecking accept-new
        '';

        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.srv-lx-hoo-installer = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = "srv-lx-hoo-installer";

    modules = singleton (
      { ... }:
      {
        imports = installerModules;

        dsqr.nixos.installer = {
          enable = true;
          hostName = "srv-lx-hoo-installer";
          targetHostName = hostName;
        };

        system.stateVersion = "25.05";
      }
    );
  };
}
