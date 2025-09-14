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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
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
    in
    {
      # ------------------------------------------------------------
      # NixOS module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      nixosModules.default =
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
      # Darwin module (importable in other flakes or inline configs)
      # ------------------------------------------------------------
      darwinModules.default =
        inputs:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ ./modules/darwin/default.nix ];
          options.dsqrDevbox = (import ./config.nix lib).dsqrDevboxOptions;
          config.nixpkgs.config.allowUnfree = true;
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
    };
}
