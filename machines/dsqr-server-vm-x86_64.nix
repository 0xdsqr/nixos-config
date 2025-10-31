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

  networking.hostName = "server";
  networking.domain = "dsqr.dev";
  networking.firewall.allowedTCPPorts = [
    3000
    3001
    8080
    5432
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = [ "dsqr" ];
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            md5
      host    all             all             ::1/128                 md5
      host    all             all             0.0.0.0/0               md5
    '';
    settings = {
      max_connections = 100;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      work_mem = "4MB";
      log_statement = "all";
      max_wal_size = "1GB";
      min_wal_size = "80MB";
    };
    initialScript = pkgs.writeText "init.sql" ''
      CREATE USER dsqr WITH PASSWORD 'change-me-in-production';
      GRANT ALL PRIVILEGES ON DATABASE dsqr TO dsqr;
    '';
  };

  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      listen = [
        { addr = "0.0.0.0"; port = 8080; }
      ];
      locations."/api/" = {
        proxyPass = "http://localhost:3001/api/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
      locations."/" = {
        proxyPass = "http://localhost:3000/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  system.stateVersion = "25.05";
}