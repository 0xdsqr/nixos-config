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

  networking.hostName = "smart-home";
  networking.domain = "dsqr.dev";
  networking.firewall.allowedTCPPorts = [
    80    # Nginx (proxies to Frigate)
    #8123 # Home Assistant
    #1883 # MQTT
  ];

  # Enable nginx - required for Frigate to be accessible
  services.nginx.enable = true;

  #services.mosquitto = {
  #  enable = true;
  #  listeners = [{
  #    acl = [ "pattern readwrite #" ];
  #    omitPasswordAuth = true;
  #    settings.allow_anonymous = true;
  #  }];
  #};

  services.frigate = {
    enable = true;
    hostname = "localhost";  # This is for nginx vhost, not bind address
    
    settings = {
      #mqtt = { enabled = true; host = "127.0.0.1";};
      
      # Use CPU for detection (we'll upgrade to GPU later)
      detectors = {
        cpu = {
          type = "cpu";
          num_threads = 3;
        };
      };
      
      cameras = { };
    };
  };

  #services.home-assistant = {
  #  enable = true;
  #  extraComponents = [
  #    "met"
  #    "mqtt"
  #    "frigate"
  #  ];
  #  config = {
  #    default_config = {};
  #  };
  #};

  system.stateVersion = "25.05";
}