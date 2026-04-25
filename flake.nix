{
  description = "Dave's homelab";
  nixConfig = {
    extra-substituters = [ "https://exo.cachix.org" ];

    extra-trusted-public-keys = [ "exo.cachix.org-1:okq7hl624TBeAR3kV+g39dUFSiaZgLRkLsFBCuJ2NZI=" ];

    experimental-features = [
      "flakes"
      "nix-command"
    ];

    flake-registry = "";
    show-trace = true;
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";

      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";

      flake = false;
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rustfs = {
      url = "github:rustfs/rustfs-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    exo.url = "github:exo-explore/exo";

    agenix = {
      url = "github:ryantm/agenix";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.home-manager.follows = "home-manager";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter = {
      url = "github:nix-community/nixos-facter-modules";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ublock = {
      url = "github:gorhill/uBlock";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
      inherit (nixLib.filesystem) listFilesRecursive;
      inherit (nixLib.lists) elem filter;
      inherit (nixLib.strings) hasPrefix hasSuffix;

      collectNix =
        {
          dir,
          ignoredNames ? [ ],
          ignoredFiles ? [ ],
          ignoredDirectories ? [ ],
        }:
        filter (
          path:
          let
            name = builtins.baseNameOf path;
            pathString = toString path;
          in
          hasSuffix ".nix" pathString
          && !(elem name ignoredNames)
          && !(elem path ignoredFiles)
          && !(builtins.any (ignoredDir: hasPrefix "${toString ignoredDir}/" pathString) ignoredDirectories)
        ) (listFilesRecursive dir);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.home-manager.flakeModules.home-manager
        ./parts/flake-outputs.nix
        ./parts/per-system.nix
      ]
      ++ collectNix {
        dir = ./modules;
        ignoredFiles = [
          ./modules/home/neovim/init-lua.nix
          ./modules/home/neovim/packages.nix
        ];
        ignoredDirectories = [ ./modules/home/neovim/plugins ];
      }
      ++ [ ./parts/hosts.nix ];
    };
}
