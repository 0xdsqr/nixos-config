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

  hostName = "srv-lx-knox";

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
    sshHost = "10.10.30.109";
    system = "x86_64-linux";
  };

  flake.nixosConfigurations.${hostName} = self.lib.nixosSystem {
    inherit hostName;

    modules = singleton (
      { lib, pkgs, ... }: {
        imports =
          modules
          ++ self.lib.collectNix {
            path = ./.;
            exclude = path: path == ./default.nix;
          };

        networking.hostName = hostName;

        hardware.report = ./srv-lx-knox.report.json;

        allowedUnfreePackageNames = [ "vault-bin" ];

        dsqr.nixos = {
          openssh.enable = true;
          postgresql = {
            enable = true;
            package = pkgs.postgresql_18;
          };
          proxmox.enable = true;
          tailscale.enable = true;
          user.enable = true;
        };

        services.postgresql.initdbArgs = lib.mkForce [
          "--locale=C"
          "--encoding=UTF8"
          "--data-checksums"
        ];

        home-manager.users.dsqr = {
          programs.pi.enable = false;

          dsqr.home = {
            aws.enable = false;
            bat.enable = false;
            btop.enable = true;
            claudeCode.enable = false;
            codex.enable = false;
            difftastic.enable = false;
            hushlogin.enable = false;
            neovim = {
              enable = true;
              initLua.enable = false;
              packages.enable = false;
              plugins.enable = false;
            };
            nu.enable = true;
            opencode.enable = false;
            pi-bridge.enable = false;
            ssh.enable = true;
            starship.enable = true;
            tailscale.enable = false;
            versionControl.enable = true;
            xdg.enable = true;

            packages = {
              containers.enable = false;
              databases.enable = false;
              debugging.enable = false;
              kubernetes.enable = false;
              media.enable = false;
              networkTools.enable = true;
              node.enable = false;
              shellUtils.enable = true;
              signing.enable = false;
            };

            desktop = {
              browsers.helium.enable = false;
              ghostty.enable = false;
            };
          };
        };

        system.stateVersion = "25.05";
      }
    );
  };

  flake.nixosConfigurations.srv-lx-knox-installer = self.lib.nixosSystem {
    hostMeta = self.hostDefinitions.${hostName};
    hostName = "srv-lx-knox-installer";

    modules = singleton (
      { lib, ... }: {
        imports = installerModules;

        dsqr.nixos = {
          fonts.enable = lib.mkForce false;
          tailscale.enable = lib.mkForce false;

          installer = {
            enable = true;
            hostName = "srv-lx-knox-installer";
            targetHostName = hostName;
          };
        };

        home-manager.users.dsqr = {
          programs.pi.enable = false;

          dsqr.home = {
            aws.enable = false;
            bat.enable = false;
            btop.enable = false;
            claudeCode.enable = false;
            codex.enable = false;
            difftastic.enable = false;
            hushlogin.enable = false;
            neovim.enable = false;
            nu.enable = false;
            opencode.enable = false;
            pi-bridge.enable = false;
            ssh.enable = false;
            starship.enable = false;
            tailscale.enable = false;
            versionControl.enable = false;
            xdg.enable = false;

            packages = {
              containers.enable = false;
              databases.enable = false;
              debugging.enable = false;
              kubernetes.enable = false;
              media.enable = false;
              networkTools.enable = false;
              node.enable = false;
              shellUtils.enable = false;
              signing.enable = false;
            };

            desktop = {
              browsers.helium.enable = false;
              ghostty.enable = false;
            };
          };
        };

        system.stateVersion = "25.05";
      }
    );
  };
}
