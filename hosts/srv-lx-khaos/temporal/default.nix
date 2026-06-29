{ config, ... }:
let
  numHistoryShards = 512;
  broadcastAddress = "127.0.0.1";

  postgres = {
    host = "127.0.0.1";
    port = 5432;
    user = "temporal";
    database = "temporal";
    visibilityDatabase = "temporal_visibility";
    pluginName = "postgres12";
    sslMode = "disable";
    passwordEnvVar = "TEMPORAL_POSTGRES_PASSWORD";
  };

  frontend = {
    bindAddress = "0.0.0.0";
    advertisedAddress = "10.10.30.107";
    grpcPort = 7233;
    httpPort = 7243;
    membershipPort = 6933;
  };

  matching = {
    grpcPort = 7235;
    membershipPort = 6935;
  };

  history = {
    grpcPort = 7234;
    membershipPort = 6934;
  };

  worker = {
    grpcPort = 7239;
    membershipPort = 6939;
  };

  metrics = {
    listenAddress = "127.0.0.1";
    port = 8000;
    framework = "tally";
  };

  ui = {
    bindAddress = "10.10.30.107";
    port = 8088;
    publicOrigin = "https://temporal.home.arpa";
  };
in
{
  dsqr.nixos.temporal = {
    enable = true;
    environmentFiles = [ config.age.secrets.temporalPostgresEnv.path ];

    cli.enable = true;

    ui = {
      enable = true;
      host = ui.bindAddress;
      inherit (ui) port;
      temporalGRPCAddress = "127.0.0.1:${toString frontend.grpcPort}";
      corsAllowOrigins = [ ui.publicOrigin ];
      cookieInsecure = false;
      openFirewall = true;
    };

    configText = ''
      # enable-template

      log:
        stdout: true
        level: "info"

      persistence:
        defaultStore: postgres-default
        visibilityStore: postgres-visibility
        numHistoryShards: ${toString numHistoryShards}
        datastores:
          postgres-default:
            sql:
              pluginName: "${postgres.pluginName}"
              databaseName: "${postgres.database}"
              connectAddr: "${postgres.host}:${toString postgres.port}"
              connectProtocol: "tcp"
              user: "${postgres.user}"
              password: {{ env "${postgres.passwordEnvVar}" | quote }}
              maxConns: 20
              maxIdleConns: 20
              maxConnLifetime: "1h"
              connectAttributes:
                sslmode: "${postgres.sslMode}"
          postgres-visibility:
            sql:
              pluginName: "${postgres.pluginName}"
              databaseName: "${postgres.visibilityDatabase}"
              connectAddr: "${postgres.host}:${toString postgres.port}"
              connectProtocol: "tcp"
              user: "${postgres.user}"
              password: {{ env "${postgres.passwordEnvVar}" | quote }}
              maxConns: 10
              maxIdleConns: 10
              maxConnLifetime: "1h"
              connectAttributes:
                sslmode: "${postgres.sslMode}"

      global:
        membership:
          maxJoinDuration: "30s"
          broadcastAddress: "${broadcastAddress}"
        metrics:
          prometheus:
            framework: "${metrics.framework}"
            timerType: "histogram"
            listenAddress: "${metrics.listenAddress}:${toString metrics.port}"

      services:
        frontend:
          rpc:
            grpcPort: ${toString frontend.grpcPort}
            membershipPort: ${toString frontend.membershipPort}
            bindOnIP: "${frontend.bindAddress}"
            httpPort: ${toString frontend.httpPort}

        matching:
          rpc:
            grpcPort: ${toString matching.grpcPort}
            membershipPort: ${toString matching.membershipPort}
            bindOnLocalHost: true

        history:
          rpc:
            grpcPort: ${toString history.grpcPort}
            membershipPort: ${toString history.membershipPort}
            bindOnLocalHost: true

        worker:
          rpc:
            grpcPort: ${toString worker.grpcPort}
            membershipPort: ${toString worker.membershipPort}
            bindOnLocalHost: true

      clusterMetadata:
        enableGlobalNamespace: false
        failoverVersionIncrement: 10
        masterClusterName: "active"
        currentClusterName: "active"
        clusterInformation:
          active:
            enabled: true
            initialFailoverVersion: 1
            rpcName: "frontend"
            rpcAddress: "${frontend.advertisedAddress}:${toString frontend.grpcPort}"
            httpAddress: "${frontend.advertisedAddress}:${toString frontend.httpPort}"

      dcRedirectionPolicy:
        policy: "noop"

      archival:
        history:
          state: "enabled"
          enableRead: true
          provider:
            filestore:
              fileMode: "0666"
              dirMode: "0766"
            gstorage:
              credentialsPath: "/tmp/gcloud/keyfile.json"
        visibility:
          state: "enabled"
          enableRead: true
          provider:
            filestore:
              fileMode: "0666"
              dirMode: "0766"

      namespaceDefaults:
        archival:
          history:
            state: "disabled"
            URI: "file:///tmp/temporal_archival"
          visibility:
            state: "disabled"
            URI: "file:///tmp/temporal_visibility_archival"
    '';
  };

  networking.firewall.allowedTCPPorts = [ frontend.grpcPort ];

  systemd.services.temporal = {
    requires = [ "temporal-postgresql-schema.service" ];
    after = [ "temporal-postgresql-schema.service" ];
  };
}
