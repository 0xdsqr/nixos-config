{
  description = "Dave's homelab";
  nixConfig = {
    extra-substituters = [ "https://exo.cachix.org" ];

    extra-trusted-public-keys = [ "exo.cachix.org-1:okq7hl624TBeAR3kV+g39dUFSiaZgLRkLsFBCuJ2NZI=" ];

    experimental-features = [
      "flakes"
      "nix-command"
    ];

    builders-use-substitutes = true;
    flake-registry = "";
    show-trace = true;
    trusted-users = [
      "@wheel"
      "dsqr"
      "@build"
    ];
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
      url = "github:0xdsqr/nix-openclaw/slop";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-steipete-tools = {
      url = "github:0xdsqr/nix-steipete-tools/main";
      inputs.nixpkgs.follows = "nixpkgs";
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
      inherit (inputs.nixpkgs.lib.filesystem) listFilesRecursive;
      inherit (inputs.nixpkgs.lib.lists) sort;
      inherit (inputs.nixpkgs.lib.strings) hasInfix hasSuffix;

      # Bootstrap copy of self.lib.collectNix. The flake has to discover and import
      # modules/common/lib.nix before self.lib exists, so this stays local here.
      collectNix =
        {
          path,
          exclude ? _: false,
        }:
        sort (a: b: toString a < toString b) (
          builtins.filter (file: hasSuffix ".nix" (toString file) && !(exclude file)) (listFilesRecursive path)
        );

      moduleImports = collectNix {
        path = ./modules;
        exclude =
          path:
          let
            pathString = toString path;
          in
          hasSuffix "/common/keys.nix" pathString
          || hasInfix "/home/neovim/plugins/" pathString
          || hasSuffix "/home/neovim/init-lua.nix" pathString
          || hasSuffix "/home/neovim/packages.nix" pathString;
      };

      hostImports = collectNix {
        path = ./hosts;
        exclude =
          path:
          let
            pathString = toString path;
          in
          builtins.match ".*/hosts/[^/]+/default\\.nix" pathString == null
          || hasSuffix "/hosts/srv-lx-hoo/default.nix" pathString;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        imports = [ inputs.home-manager.flakeModules.home-manager ] ++ moduleImports ++ hostImports;

        perSystem =
          { pkgs, ... }:
          let
            treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.nix";

              programs.nixfmt = {
                enable = true;
                strict = true;
                width = 120;
              };

              programs.deadnix.enable = true;
              programs.statix.enable = true;
            };
          in
          {
            formatter = treefmtEval.config.build.wrapper;
            devShells.default = pkgs.mkShellNoCC {
              packages = with pkgs; [
                deadnix
                nil
                nixd
                statix
                treefmtEval.config.build.wrapper
              ];
            };

            checks = {
              formatting = treefmtEval.config.build.check ./.;
            };
          };
      }
    );
}
