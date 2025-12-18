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

  # Override github-runner to latest version
  nixpkgs.overlays = [
    (final: prev: {
      github-runner = prev.github-runner.overrideAttrs (old: rec {
        version = "2.321.0";
        src = prev.fetchFromGitHub {
          owner = "actions";
          repo = "runner";
          rev = "v${version}";
          hash = "sha256-KZ072v5kYlD78RGQl13Aj05DGzj2+r2akzyZ1aJn93A=";
          leaveDotGit = true;
          postFetch = ''
            git -C $out rev-parse --short HEAD > $out/.git-revision
            rm -rf $out/.git
          '';
        };
      });
    })
  ];

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
    };
  };

  system.stateVersion = "25.05";
}
