{
  description = "Dave's nixworld";

  inputs = {
    # Core Nixpkgs + compatibility
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # System/user management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Developer tools / utilities
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    # Services
    rustfs.url = "github:rustfs/rustfs";
    rustfs.inputs.nixpkgs.follows = "nixpkgs";
    media-server.url = "github:0xdsqr/media-server-nixos/master";
    media-server.inputs.nixpkgs.follows = "nixpkgs";
    dsqr-dotdev.url = "github:0xdsqr/dsqr-dotdev/main";
    dsqr-dotdev.inputs.nixpkgs.follows = "nixpkgs";

    # Developer tools (external)
    opencode.url = "github:sst/opencode/dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      sops-nix,
      treefmt-nix,
      opencode,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      mkSystem = import ./lib/mksystem.nix {
        inherit nixpkgs inputs;
        overlays = [ ];
      };

      nixosHosts = {
        devbox-vm-x86_64 = {
          system = "x86_64-linux";
          user = "dsqr";
          homeManager = true;
        };
        devbox-usb-x86_64 = {
          system = "x86_64-linux";
          user = "dsqr";
          homeManager = true;
        };
        dsqr-server-vm-x86_64 = {
          system = "x86_64-linux";
          user = "sysdsqr";
          homeManager = true;
        };
        gateway-vm-x86_64 = {
          system = "x86_64-linux";
          user = "sysdsqr";
          homeManager = true;
        };
        github-runner-vm-x86_64 = {
          system = "x86_64-linux";
          user = "sysdsqr";
          homeManager = true;
        };
        cellar-vm-x86_64 = {
          system = "x86_64-linux";
          user = "sysdsqr";
          homeManager = true;
        };
        media-server-vm-x86_64 = {
          system = "x86_64-linux";
          user = "sysdsqr";
          homeManager = true;
        };
      };

      darwinHosts = {
        devbox-macbook-pro-m1 = {
          system = "aarch64-darwin";
          user = "dsqr";
          darwin = true;
          homeManager = true;
        };
        dsqr-mini-001 = {
          system = "aarch64-darwin";
          user = "dsqr";
          darwin = true;
          homeManager = true;
          machineConfig = ./machines/mini-cluster.nix;
          userOSConfig = ./users/cluster/darwin.nix;
          homeManagerConfig = ./users/cluster/home-manager-mini.nix;
        };
      };
    in
    {
      # ------------------------------------------------------------
      # NixOS module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      nixosModules.dsqr-nix =
        inputs:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ (import ./modules/nixos/default.nix inputs) ];
          options.eevee = (import ./eevee-config.nix lib).eeveeOptions;
        };

      # ------------------------------------------------------------
      # Proxmox module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      nixosModules.dsqr-proxmox =
        inputs:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            (import ./modules/proxmox/default.nix inputs)
          ];
        };

      # ------------------------------------------------------------
      # GitHub Runners module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      nixosModules.github-runners =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            (import ./modules/nixos/github-runners.nix)
          ];
        };

      # ------------------------------------------------------------
      # RustFS module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      nixosModules.rustfs =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            (import ./modules/nixos/rustfs.nix)
          ];
        };

      # ------------------------------------------------------------
      # Darwin module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      darwinModules.dsqr-nix =
        inputs:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ (import ./modules/darwin/default.nix inputs) ];
          options.eevee = (import ./eevee-config.nix lib).eeveeOptions;
        };

      # ------------------------------------------------------------
      # Darwin mini-cluster module (shared for mac minis)
      # ------------------------------------------------------------
      darwinModules.dsqr-mini-cluster =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ ./modules/darwin/mini-cluster.nix ];
        };

      # ------------------------------------------------------------
      # Home Manager module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      homeManagerModules.eevee =
        inputs:
        {
          config,
          lib,
          pkgs,
          osConfig ? { },
          ...
        }:
        {
          imports = [
            (import ./modules/eevee/default.nix inputs)
          ];
          options.eevee = (import ./eevee-config.nix lib).eeveeOptions;
        };

      # ------------------------------------------------------------
      # Home Manager mini module (trimmed eevee for cluster nodes)
      # ------------------------------------------------------------
      homeManagerModules.eevee-mini =
        inputs:
        {
          config,
          lib,
          pkgs,
          osConfig ? { },
          ...
        }:
        {
          imports = [
            (import ./modules/eevee/mini.nix inputs)
          ];
          options.eevee = (import ./eevee-config.nix lib).eeveeOptions;
        };

      # ------------------------------------------------------------
      # Development shell (nix develop .)
      # ------------------------------------------------------------
      devShells = forEachSystem (
        system:
        let
          devConfig = import ./devshell.nix { inherit nixpkgs system; };
        in
        devConfig.devShells.${system}
      );

      # ------------------------------------------------------------
      # Formatter (nix fmt)
      # ------------------------------------------------------------
      formatter = forEachSystem (
        system:
        (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix).config.build.wrapper
      );

      # ------------------------------------------------------------
      # Checks (nix flake check)
      # Runs treefmt in check mode to ensure the repo is properly formatted.
      # Useful in CI to fail builds if formatting or linting issues exist.
      # ------------------------------------------------------------
      checks = forEachSystem (system: {
        formatting =
          (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix).config.build.check
            self;
      });

      # ------------------------------------------------------------
      # Packages (nix build .#sysdsqr)
      # ------------------------------------------------------------
      packages = forEachSystem (system: {
        sysdsqr = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/sysdsqr-cli { };
        sysdsqr-cli = self.packages.${system}.sysdsqr;
        opencode = opencode.packages.${system}.default;
        default = self.packages.${system}.sysdsqr;
      });

      # ------------------------------------------------------------
      # Apps (nix run .#sysdsqr)
      # ------------------------------------------------------------
      apps = forEachSystem (system: {
        sysdsqr = {
          type = "app";
          program = "${self.packages.${system}.sysdsqr}/bin/sysdsqr";
        };
        sysdsqr-cli = self.apps.${system}.sysdsqr;
        default = self.apps.${system}.sysdsqr;
      });

      # ------------------------------------------------------------
      # System Configurations
      # ------------------------------------------------------------
      nixosConfigurations = nixpkgs.lib.mapAttrs (name: cfg: mkSystem name cfg) nixosHosts;
      darwinConfigurations = nixpkgs.lib.mapAttrs (name: cfg: mkSystem name cfg) darwinHosts;

      lib.mkSystem = mkSystem;
    };
}
