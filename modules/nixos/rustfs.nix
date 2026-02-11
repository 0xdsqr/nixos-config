{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dsqr-rustfs;
in
{
  options.services.dsqr-rustfs = {
    enable = lib.mkEnableOption "RustFS S3-compatible object storage";

    package = lib.mkOption {
      type = lib.types.package;
      description = "RustFS package to use";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "rustfs";
      description = "User under which RustFS runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "rustfs";
      description = "Group under which RustFS runs";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/rustfs/data";
      description = "Directory for RustFS data storage";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for S3 API to listen on";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Port for S3 API";
    };

    consoleAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for web console to listen on";
    };

    consolePort = lib.mkOption {
      type = lib.types.port;
      default = 9001;
      description = "Port for web console";
    };

    rootCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing environment variables for root credentials.
        Should contain:
          RUSTFS_ROOT_USER=yourusername
          RUSTFS_ROOT_PASSWORD=yourpassword (min 8 chars)

        If null, uses default credentials (not recommended for production).
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open firewall ports for RustFS";
    };
  };

  config = lib.mkIf cfg.enable {
    # User and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/rustfs";
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    # Data directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d /var/lib/rustfs/logs 0750 ${cfg.user} ${cfg.group} -"
    ];

    # Systemd service
    systemd.services.rustfs = {
      description = "RustFS S3-Compatible Object Storage";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = lib.mkIf (cfg.rootCredentialsFile == null) {
        RUSTFS_ROOT_USER = "rustfsadmin";
        RUSTFS_ROOT_PASSWORD = "rustfsadmin";
      };

      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/rustfs \
            --address ${cfg.address}:${toString cfg.port} \
            --console-enable \
            --console-address ${cfg.consoleAddress}:${toString cfg.consolePort} \
            ${cfg.dataDir}
        '';

        EnvironmentFile = lib.mkIf (cfg.rootCredentialsFile != null) cfg.rootCredentialsFile;

        Restart = "always";
        RestartSec = "10s";

        User = cfg.user;
        Group = cfg.group;

        StateDirectory = "rustfs";
        WorkingDirectory = "/var/lib/rustfs";

        # Security hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [
          cfg.dataDir
          "/var/lib/rustfs"
        ];

        # Resource limits
        LimitNOFILE = 65536;
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.port
      cfg.consolePort
    ];

    # Add CLI to system packages
    environment.systemPackages = [ cfg.package ];
  };
}
