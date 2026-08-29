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

  hostName = "srv-lx-k8s-indigo-worker-03";

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
    sshHost = "10.10.80.105";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { ... }: {
        imports =
          modules
          ++ [ ../../profiles/kubernetes/nixos.nix ]
          ++ self.lib.collectNix {
            path = ./.;
            exclude = path: path == ./default.nix;
          };

        networking = {
          inherit hostName;
          timeServers = [ "10.10.80.1" ];
        };
        dsqr.nixos = {
          kubeadm = {
            role = "worker";
            nodeAddress = "10.10.80.105";

            cluster = {
              name = "indigo";
              apiEndpoint = "10.10.80.10:6443";
              apiVip = "10.10.80.10";
              podSubnet = "10.80.0.0/16";
              serviceSubnet = "10.81.0.0/16";
              disableKubeProxy = true;
            };
          };

          tailscale.enable = true;
        };
        hardware.report = ./srv-lx-k8s-indigo-worker-03.report.json;
        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.${hostName + "-installer"} = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = hostName + "-installer";

    modules = singleton (
      { lib, ... }: {
        imports = installerModules ++ [ ../../profiles/server/nixos.nix ];

        dsqr.nixos = {
          fonts.enable = lib.mkForce false;
          tailscale.enable = lib.mkForce false;

          installer = {
            enable = true;
            hostName = hostName + "-installer";
            targetHostName = hostName;
          };
        };

        system.stateVersion = "25.05";
      }
    );
  };
}
