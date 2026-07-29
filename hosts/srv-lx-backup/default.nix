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

  hostName = "srv-lx-backup";

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
    sshHost = "10.10.30.111";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { ... }: {
        imports =
          modules
          ++ [ ../../profiles/server/nixos.nix ]
          ++ self.lib.collectNix {
            path = ./.;
            exclude = path: path == ./default.nix;
          };

        networking.hostName = hostName;

        hardware.report = ./srv-lx-backup.report.json;

        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.srv-lx-backup-installer = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = "srv-lx-backup-installer";

    modules = singleton (
      { lib, ... }: {
        imports = installerModules ++ [ ../../profiles/server/nixos.nix ];

        dsqr.nixos = {
          fonts.enable = lib.mkForce false;
          tailscale.enable = lib.mkForce false;

          installer = {
            enable = true;
            hostName = "srv-lx-backup-installer";
            targetHostName = hostName;
          };
        };

        system.stateVersion = "25.05";
      }
    );
  };
}
