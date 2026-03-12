{
  inputs,
  pkgs,
  ...
}:
let
  mkRunner =
    repo:
    profile: overrides:
    {
      url = "https://github.com/0xdsqr/${repo}";
      tokenSecret = "github_runners/${repo}/token";
    }
    // profile
    // overrides;

  profiles = rec {
    nix = {
      extraLabels = [ "profile-nix" ];
      extraPackages = with pkgs; [
        git
        nixfmt-rfc-style
        nil
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
