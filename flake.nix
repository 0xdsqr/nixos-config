{
  description = "Dave's nixworld";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-colors.url = "github:misterio77/nix-colors";
    hyprland.url = "github:hyprwm/Hyprland";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      nix-colors,
      treefmt-nix,
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
          options.dsqrDevbox = (import ./config.nix lib).dsqrDevboxOptions;
          config.nixpkgs.config.allowUnfree = true;
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
            (import ./modules/proxmox/default.nix)
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
          options.dsqrDevbox = (import ./config.nix lib).dsqrDevboxOptions;
          config.nixpkgs.config.allowUnfree = true;
        };

      # ------------------------------------------------------------
      # Home Manager module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      homeManagerModules.dsqr-nix =
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
            nix-colors.homeManagerModules.default
            (import ./modules/home-manager/default.nix inputs)
          ];
          options.dsqrDevbox = (import ./config.nix lib).dsqrDevboxOptions;
          config = lib.mkIf (osConfig ? dsqrDevbox) {
            dsqrDevbox = osConfig.dsqrDevbox;
          };
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
      # Nixos System Configurtations
      # ------------------------------------------------------------
      nixosConfigurations.devbox-vm-x86_64 = mkSystem "devbox-vm-x86_64" {
        system = "x86_64-linux";
        user = "dsqr";
        darwin = false;
        homeManager = true;
      };

      # ------------------------------------------------------------
      # Dariwn Configurtations
      # ------------------------------------------------------------
      darwinConfigurations.devbox-macbook-pro-m1 = mkSystem "devbox-macbook-pro-m1" {
        system = "aarch64-darwin";
        user = "dsqr";
        darwin = true;
        homeManager = true;
      };
    };
}
