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
          nodejs_22
        ];
        nodeRuntimes = [ "node22" ];
      };
    };
  };

  system.stateVersion = "25.05";
}
