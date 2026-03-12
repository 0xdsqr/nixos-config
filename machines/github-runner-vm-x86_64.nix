{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mergeProfiles =
    left: right:
    ({
      extraLabels = lib.unique ((left.extraLabels or [ ]) ++ (right.extraLabels or [ ]));
      extraPackages = lib.unique ((left.extraPackages or [ ]) ++ (right.extraPackages or [ ]));
      extraEnvironment = lib.recursiveUpdate (left.extraEnvironment or { }) (right.extraEnvironment or { });
      serviceOverrides = lib.recursiveUpdate (left.serviceOverrides or { }) (right.serviceOverrides or { });
      docker = (left.docker or false) || (right.docker or false);
    }
    // lib.optionalAttrs (
      lib.unique ((left.nodeRuntimes or [ ]) ++ (right.nodeRuntimes or [ ])) != [ ]
    ) {
      nodeRuntimes = lib.unique ((left.nodeRuntimes or [ ]) ++ (right.nodeRuntimes or [ ]));
    });

  composeProfiles =
    names:
    builtins.foldl'
      (acc: name: mergeProfiles acc profiles.${name})
      { }
      names;

  mkRunner =
    repo:
    profile: overrides:
    {
      url = "https://github.com/0xdsqr/${repo}";
      tokenSecret = "github_runners/${repo}/token";
    }
    // profile
    // overrides;

  profiles = {
    nix = {
      extraLabels = [ "profile-nix" ];
      extraPackages = with pkgs; [
        git
        xz
        nixfmt-rfc-style
        nil
      ];
    };

    go = {
      extraLabels = [
        "profile-go"
        "go"
      ];
      extraPackages = [
        pkgs.go
        pkgs.gopls
        pkgs.delve
        pkgs.golangci-lint
        pkgs.goreleaser
        pkgs.gh
        pkgs.gnupg
        pkgs.deadnix
        pkgs.statix
      ];
    };
  };
in
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.self.nixosModules.github-runners
    inputs.sops-nix.nixosModules.sops
  ];

  dsqr.proxmox.networking = {
    hostName = "github-runner";
  };

  environment.systemPackages = with pkgs; [ ];

  # GitHub Actions runners configuration
  dsqr.github-runners = {
    enable = true;
    sopsFile = ../secrets/hosts/github-runner-vm-x86_64.sops.yaml;

    runners = {
      nix-config = mkRunner "nixos-config" profiles.nix { };
      sys-dsqr = mkRunner "sys-dsqr" (composeProfiles [
        "nix"
        "go"
      ]) {
        extraLabels = [
          "sys-dsqr"
          "release"
        ];
      };
    };
  };

  # Nix garbage collection to prevent disk space issues
  nix.gc = {
    automatic = true;
    dates = "hourly";
    options = "--delete-older-than 3d";
  };

  # Keep store optimized and limit size
  nix.settings.auto-optimise-store = true;
  nix.settings.min-free = 1073741824; # 1GB - trigger GC when free space drops below
  nix.settings.max-free = 3221225472; # 3GB - stop GC when this much is free

  system.stateVersion = "25.05";
}
