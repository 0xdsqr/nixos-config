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

  networking.hostName = "hoo";
  networking.domain = "dsqr.dev";

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    6379
    26257
    8080
    9090
    3000
    3001
    3002
    8081
  ];

  ############################################################
  # CockroachDB — systemd service
  ############################################################

  users.groups.cockroach = { };
  users.users.cockroach = {
    isSystemUser = true;
    home = "/var/lib/cockroach";
    createHome = true;
    group = "cockroach";
  };

  systemd.services.cockroachdb = {
    description = "CockroachDB server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/cockroach";
      ExecStart = ''
        ${pkgs.cockroachdb}/bin/cockroach start-single-node \
          --insecure \
          --listen-addr=0.0.0.0:26257 \
          --http-addr=0.0.0.0:8080 \
          --store=/var/lib/cockroach \
          --cache=25% \
          --max-sql-memory=25%
      '';

      User = "cockroach";
      Group = "cockroach";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  ############################################################
  # Redis
  ############################################################
  services.redis.servers.main = {
    enable = true;
    bind = "0.0.0.0";
    port = 6379;

    settings = {
      requirepass = "changeme";

      save = [
        "900 1"
        "300 10"
        "60 10000"
      ];

      maxmemory = "256mb";
      maxmemory-policy = "allkeys-lru";

      appendonly = "yes";
      appendfsync = "everysec";
    };
  };

  ############################################################
  # Monitoring stack
  ############################################################

  services.prometheus.exporters.node.enable = true;

  services.prometheus.exporters.redis = {
    enable = true;
    extraFlags = [
      "--redis.password=changeme"
    ];
  };

  services.prometheus = {
    enable = true;

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "localhost:9100" ]; } ];
      }
      {
        job_name = "redis";
        static_configs = [ { targets = [ "localhost:9121" ]; } ];
      }
      {
        job_name = "cockroach";
        static_configs = [ { targets = [ "localhost:8080" ]; } ];
      }
    ];
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
      };
    };

    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    cockroachdb
    redis
    htop
    curl
    wget
  ];

  system.stateVersion = "25.05";
}
