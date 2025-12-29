{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  # The `nix` section configures how this system participates in the flake ecosystem.
  # - Registers every flake input so it can be referenced as `flake:<name>`
  # - Disables legacy channels in favor of pure flakes
  # - Enables `nix-command` + `flakes` features
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };

      channel.enable = false;

      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  networking.hostName = "cellar";
  networking.domain = "dsqr.dev";

  # --- Static IP configuration ---
  networking.useDHCP = false;

  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = "192.168.50.35";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "192.168.50.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  environment.systemPackages = with pkgs; [ ];

  system.stateVersion = "25.05";
}
