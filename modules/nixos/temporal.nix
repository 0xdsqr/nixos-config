{
  flake.nixosModules.temporal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) optional;
      inherit (lib.modules) mkForce mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.types)
        attrs
        bool
        int
        lines
        listOf
        nullOr
        str
        ;

      cfg = config.dsqr.nixos.temporal;
      renderedConfig = pkgs.writeText "temporal-server.yaml" cfg.configText;
      renderedUiConfig = pkgs.writeText "temporal-ui.yaml" (
        lib.generators.toYAML { } (
          {
            host = cfg.ui.host;
            port = cfg.ui.port;
            temporalGrpcAddress = cfg.ui.temporalGRPCAddress;
            publicPath = cfg.ui.publicPath;
            enableUi = true;
            defaultNamespace = cfg.ui.defaultNamespace;
            cors = {
              cookieInsecure = cfg.ui.cookieInsecure;
              unsafeAllowAllOrigins = false;
              allowOrigins = cfg.ui.corsAllowOrigins;
            };
            auth.enabled = false;
            tls.enableHostVerification = false;
          }
          // lib.optionalAttrs (cfg.ui.forwardHeaders != [ ]) { forwardHeaders = cfg.ui.forwardHeaders; }
        )
      );
    in
    {
      options.dsqr.nixos.temporal = {
        enable = mkEnableOption "Enable Temporal server";

        package = mkPackageOption pkgs "Temporal server" { default = [ "temporal" ]; };

        settings = mkOption {
          type = attrs;
          default = { };
          description = "Temporal server settings passed to upstream services.temporal.settings.";
        };

        configText = mkOption {
          type = nullOr lines;
          default = null;
          description = "Complete Temporal server config text. Use when official config templating is needed.";
        };

        environmentFiles = mkOption {
          type = listOf str;
          default = [ ];
          description = "Environment files loaded by temporal.service.";
        };

        cli = {
          enable = mkEnableOption "Install the Temporal CLI";

          package = mkPackageOption pkgs "Temporal CLI" { default = [ "temporal-cli" ]; };
        };

        ui = {
          enable = mkEnableOption "Enable Temporal Web UI";

          package = mkPackageOption pkgs "Temporal UI server" { default = [ "temporal-ui-server" ]; };

          environment = mkOption {
            type = str;
            default = "production";
            description = "Temporal UI runtime environment and config filename.";
          };

          host = mkOption {
            type = str;
            default = "127.0.0.1";
            description = "Address for the Temporal UI HTTP server to bind.";
          };

          port = mkOption {
            type = int;
            default = 8080;
            description = "Port for the Temporal UI HTTP server to bind.";
          };

          temporalGRPCAddress = mkOption {
            type = str;
            default = "127.0.0.1:7233";
            description = "Temporal frontend gRPC address used by the UI server.";
          };

          publicPath = mkOption {
            type = str;
            default = "";
            description = "URL path prefix for the Temporal UI.";
          };

          defaultNamespace = mkOption {
            type = str;
            default = "default";
            description = "Default Temporal namespace selected in the UI.";
          };

          corsAllowOrigins = mkOption {
            type = listOf str;
            default = [ ];
            description = "Allowed browser origins for the Temporal UI HTTP API.";
          };

          cookieInsecure = mkOption {
            type = bool;
            default = false;
            description = "Allow the Temporal UI CSRF cookie over plain HTTP.";
          };

          forwardHeaders = mkOption {
            type = listOf str;
            default = [ ];
            description = "Additional HTTP headers forwarded from UI requests to Temporal.";
          };

          openFirewall = mkOption {
            type = bool;
            default = false;
            description = "Open the Temporal UI port in the host firewall.";
          };
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          services.temporal = {
            enable = true;
            inherit (cfg) package settings;
          };

          systemd.services.temporal.serviceConfig.EnvironmentFile = cfg.environmentFiles;
        }

        (mkIf (cfg.configText != null) {
          environment.etc."temporal/temporal-server.yaml".source = mkForce renderedConfig;
          systemd.services.temporal.restartTriggers = optional config.services.temporal.restartIfChanged renderedConfig;
        })

        (mkIf cfg.cli.enable { environment.systemPackages = [ cfg.cli.package ]; })

        (mkIf cfg.ui.enable {
          environment.etc."temporal-ui/${cfg.ui.environment}.yaml".source = renderedUiConfig;

          networking.firewall.allowedTCPPorts = mkIf cfg.ui.openFirewall [ cfg.ui.port ];

          systemd.services.temporal-ui = {
            description = "Temporal Web UI";
            wantedBy = [ "multi-user.target" ];
            requires = [ "temporal.service" ];
            after = [
              "network-online.target"
              "temporal.service"
            ];

            restartTriggers = [ renderedUiConfig ];

            serviceConfig = {
              ExecStart = "${cfg.ui.package}/bin/temporal-ui-server --root / --config etc/temporal-ui --env ${cfg.ui.environment} start";
              Restart = "on-failure";
              RestartSec = "5s";
              DynamicUser = true;
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
            };
          };
        })
      ]);
    };
}
