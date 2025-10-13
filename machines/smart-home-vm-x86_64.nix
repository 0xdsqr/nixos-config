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

  # Enable nginx - required for Frigate
  services.nginx.enable = true;

  services.mosquitto = {
    enable = true;
    listeners = [{
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };
  
  services.frigate = {
    enable = true;
    hostname = "localhost";
    
    settings = {
      # CPU detection
      detectors = {
        cpu = {
          type = "cpu";
          num_threads = 3;
        };
      };
      
      # AMCREST CAMERA
      cameras = {
        amcrest_camera = {
          enabled = true;
          
          ffmpeg = {
            inputs = [{
              # UPDATE with your password!
              path = "rtsp://admin:yourpassword@192.168.50.239:554/cam/realmonitor?channel=1&subtype=0";
              roles = ["detect" "record"];
            }];
          };
          
          # Detection settings
          detect = {
            enabled = true;
            width = 1920;
            height = 1080;
            fps = 5;
          };
          
          # What to detect
          objects = {
            track = ["person" "car" "dog" "cat"];
          };
          
          # Recording - motion only
          record = {
            enabled = true;
            retain = {
              days = 7;
              mode = "motion";
            };
          };
          
          # Snapshots
          snapshots = {
            enabled = true;
            retain = {
              default = 14;
            };
          };
        };
      };
    };
  };

  system.stateVersion = "25.05";
}