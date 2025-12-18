{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dsqr-cockroachdb;

  # Helper to construct the cockroach command
  startCommand =
    let
      commonArgs = [
        "--store=${cfg.dataDir}"
        "--listen-addr=${cfg.listen.address}:${toString cfg.listen.port}"
        "--http-addr=${cfg.http.address}:${toString cfg.http.port}"
        "--cache=${cfg.cache}"
        "--max-sql-memory=${cfg.maxSqlMemory}"
      ]
      ++ lib.optionals (cfg.locality != null) [ "--locality=${cfg.locality}" ]
      ++ lib.optionals (cfg.advertiseAddr != null) [ "--advertise-addr=${cfg.advertiseAddr}" ]
      ++ cfg.extraArgs;

      secureArgs = lib.optionals cfg.secure [
        "--certs-dir=${cfg.certsDir}"
      ];

      insecureArgs = lib.optionals (!cfg.secure) [
        "--insecure"
      ];

      clusterArgs = lib.optionals (cfg.join != [ ]) [
        "--join=${lib.concatStringsSep "," cfg.join}"
      ];
    in
    if cfg.singleNode then
      lib.concatStringsSep " \\\n  " (
        [
          "${cfg.package}/bin/cockroach start-single-node"
        ]
        ++ commonArgs
        ++ secureArgs
        ++ insecureArgs
      )
    else
      lib.concatStringsSep " \\\n  " (
        [
          "${cfg.package}/bin/cockroach start"
        ]
        ++ commonArgs
        ++ secureArgs
        ++ insecureArgs
        ++ clusterArgs
      );
in
{
  options.services.dsqr-cockroachdb = {
    enable = lib.mkEnableOption "DSQR CockroachDB database server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cockroachdb;
      defaultText = lib.literalExpression "pkgs.cockroachdb";
      description = "CockroachDB package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "cockroach";
      description = "User account under which CockroachDB runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "cockroach";
      description = "Group account under which CockroachDB runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/cockroach";
      description = "Directory where CockroachDB stores its data.";
    };

    singleNode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to run CockroachDB in single-node mode.
        Set to false for multi-node cluster deployments.
      '';
    };

    listen = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        example = "0.0.0.0";
        description = ''
          Address to listen on for SQL connections.
          Use "0.0.0.0" to listen on all interfaces.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 26257;
        description = "Port for SQL connections.";
      };
    };

    http = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        example = "0.0.0.0";
        description = ''
          Address to listen on for HTTP Admin UI.
          Use "0.0.0.0" to listen on all interfaces.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port for HTTP Admin UI.";
      };
    };

    advertiseAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "node1.example.com:26257";
      description = ''
        Address to advertise to other nodes in the cluster.
        Required for multi-node deployments.
      '';
    };

    locality = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "region=us-east,datacenter=us-east-1";
      description = ''
        Locality information for this node (used for data placement).
        Format: key=value pairs separated by commas.
      '';
    };

    join = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "node1.example.com:26257"
        "node2.example.com:26257"
        "node3.example.com:26257"
      ];
      description = ''
        List of addresses to join for multi-node cluster.
        Ignored when singleNode is true.
      '';
    };

    cache = lib.mkOption {
      type = lib.types.str;
      default = "25%";
      example = "512MiB";
      description = ''
        Size of the cache for storing SQL data.
        Can be a percentage (e.g., "25%") or absolute value (e.g., "512MiB").
      '';
    };

    maxSqlMemory = lib.mkOption {
      type = lib.types.str;
      default = "25%";
      example = "1GiB";
      description = ''
        Maximum memory for SQL queries.
        Can be a percentage (e.g., "25%") or absolute value (e.g., "1GiB").
      '';
    };

    secure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to run CockroachDB in secure mode with TLS certificates.
        When true, you must provide certificates in certsDir.
        When false, runs in insecure mode (suitable for development only).
      '';
    };

    certsDir = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.dataDir}/certs";
      defaultText = lib.literalExpression ''''${config.services.dsqr-cockroachdb.dataDir}/certs'';
      description = ''
        Directory containing TLS certificates when running in secure mode.
        Required certificates:
        - ca.crt: CA certificate
        - node.crt: Node certificate
        - node.key: Node private key
        - client.root.crt: Root client certificate
        - client.root.key: Root client private key
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to automatically open firewall ports for CockroachDB.
        Opens both the SQL port (listen.port) and HTTP port (http.port).
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--log-dir=/var/log/cockroach"
        "--max-offset=500ms"
      ];
      description = "Additional command-line arguments to pass to CockroachDB.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.secure -> (builtins.pathExists cfg.certsDir);
        message = "services.cockroachdb.certsDir must exist when running in secure mode";
      }
      {
        assertion = !cfg.singleNode -> (cfg.join != [ ]);
        message = "services.cockroachdb.join must be specified when singleNode is false";
      }
    ];

    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
      createHome = true;
      description = "CockroachDB server user";
    };

    systemd.services.dsqr-cockroachdb = {
      description = "DSQR CockroachDB Distributed SQL Database";
      documentation = [ "https://www.cockroachlabs.com/docs/" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      preStart = ''
        # Ensure data directory exists with correct permissions
        mkdir -p ${cfg.dataDir}
        chown ${cfg.user}:${cfg.group} ${cfg.dataDir}
        chmod 0700 ${cfg.dataDir}

        ${lib.optionalString cfg.secure ''
          # Ensure certs directory has correct permissions
          if [ -d ${cfg.certsDir} ]; then
            chmod 0700 ${cfg.certsDir}
            chown -R ${cfg.user}:${cfg.group} ${cfg.certsDir}
          fi
        ''}
      '';

      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = startCommand;
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "60s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ lib.optional cfg.secure cfg.certsDir;

        # Resource limits
        LimitNOFILE = 65536;
        LimitNPROC = 32768;
      };
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.listen.port
        cfg.http.port
      ];
    };

    # Add cockroachdb package to system packages for CLI access
    environment.systemPackages = [ cfg.package ];
  };
}
