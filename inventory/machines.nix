{ nixpkgs, inputs, ... }:
let
  mkMiniDarwin =
    {
      user ? "dsqr",
      system ? "aarch64-darwin",
    }:
    {
      inherit system user;
      darwin = true;
      homeManager = true;
      machineConfig = ../machines/mini-cluster.nix;
      userOSConfig = ../users/cluster/darwin.nix;
      homeManagerConfig = ../users/cluster/home-manager-mini.nix;
    };

  nixosHosts = {
    github-runner-vm-x86_64 = {
      system = "x86_64-linux";
      user = "sysdsqr";
      homeManager = true;
    };
    k8-control-plane = {
      system = "x86_64-linux";
      user = "sysdsqr";
      homeManager = true;
    };
    psql-datastore-vm-x86_64 = {
      system = "x86_64-linux";
      user = "sysdsqr";
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
  };

  darwinHosts = {
    devbox-macbook-pro-m1 = {
      system = "aarch64-darwin";
      user = "dsqr";
      darwin = true;
      homeManager = true;
    };
    dsqr-mini-001 = mkMiniDarwin { };
    dsqr-mini-002 = mkMiniDarwin { };
  };
        mkSystem = import ./lib/mksystem.nix {
        inherit nixpkgs inputs;
        overlays = [ ];
      };

in
{
  inherit darwinHosts nixosHosts mkSystem;
}
