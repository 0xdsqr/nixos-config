{
  inputs,
  pkgs,
  ...
}:
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

  # Docker support for containerized builds
  virtualisation.docker.enable = true;

  # GitHub Actions runners configuration
  dsqr.github-runners = {
    enable = true;
    sopsFile = ../secrets/hosts/github-runner-vm-x86_64.sops.yaml;

    runners = {
      nix-config = {
        url = "https://github.com/0xdsqr/nixos-config";
        tokenSecret = "github_runners/nixos-config/token";
        extraLabels = [
          "nix-config"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nixfmt-rfc-style
          nil
        ];
      };

      hoo = {
        url = "https://github.com/0xdsqr/hoo";
        tokenSecret = "github_runners/hoo/token";
        extraLabels = [
          "hoo"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nodejs_22
          # Compression tools (FlakeHub cache needs xz)
          xz
          gzip
          gnutar
          zstd
          # Common utilities
          coreutils
          curl
          jq
          # For gh release actions
          gh
          gnupg
        ];
      };

      tastingswithtay = {
        url = "https://github.com/0xdsqr/tastingswithtay";
        tokenSecret = "github_runners/tastingswithtay/token";
        count = 3;
        extraLabels = [
          "tastingswithtay"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nodejs_22
        ];
        nodeRuntimes = [ "node22" ];
      };

      media-server-nixos = {
        url = "https://github.com/0xdsqr/media-server-nixos";
        tokenSecret = "github_runners/media-server-nixos/token";
        extraLabels = [
          "media-server-nixos"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nixfmt-rfc-style
          nil
        ];
      };

      bucees-tracker = {
        url = "https://github.com/0xdsqr/bucees-tracker";
        tokenSecret = "github_runners/bucees-tracker/token";
        extraLabels = [
          "bucees-tracker"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nodejs_20
        ];
        nodeRuntimes = [ "node20" ];
      };

      dsqr-dotdev = {
        url = "https://github.com/0xdsqr/dsqr-dotdev";
        tokenSecret = "github_runners/dsqr-dotdev/token";
        extraLabels = [
          "dotdev"
          "dsqr"
        ];
        extraPackages = with pkgs; [
          git
          nodejs_24
        ];
        nodeRuntimes = [ "node24" ];
      };

      #     eazy-cli = {
      #url = "https://github.com/0xdsqr/eazy-cli";
      #tokenSecret = "github_runners/eazy-cli/token";
      #extraLabels = [
      #"dotdev"
      #"easy-cli"
      #];
      #extraPackages = with pkgs; [
      #git
      #nodejs_24
      #];
      #nodeRuntimes = [ "node24" ];
      #};
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
