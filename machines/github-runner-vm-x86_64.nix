{
  inputs,
  config,
  lib,
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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };


  networking.hostName = "github-runner";
  networking.domain = "dsqr.dev";
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  environment.systemPackages = with pkgs; [ ];

  # Docker support for containerized builds
  virtualisation.docker.enable = true;

  # GitHub Actions runners configuration
  dsqr.github-runners = {
    enable = true;
    sopsFile = ../secrets/machines/runner-hub.yaml;

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
    };
  };

  system.stateVersion = "25.05";
}
