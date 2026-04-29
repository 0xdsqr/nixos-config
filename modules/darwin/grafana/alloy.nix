{
  flake.darwinModules."grafana-alloy" =
    {
      config,
      hostName,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.strings) concatStringsSep;
      inherit (lib.types) listOf lines str;
      cfg = config.dsqr.darwin.grafana.alloy;

      alloyConfig = pkgs.writeText "config.alloy" (
        concatStringsSep "\n\n" (
          singleton /* alloy */ ''
            prometheus.exporter.unix "host" {}

            prometheus.relabel "host" {
              forward_to = [prometheus.remote_write.beacon.receiver]

              rule {
                target_label = "instance"
                replacement  = "${cfg.instance}"
              }

              rule {
                target_label = "host"
                replacement  = "${cfg.instance}"
              }

              rule {
                target_label = "role"
                replacement  = "${cfg.role}"
              }

              rule {
                target_label = "env"
                replacement  = "${cfg.environment}"
              }

              rule {
                target_label = "os"
                replacement  = "macos"
              }
            }

            prometheus.scrape "host" {
              targets         = prometheus.exporter.unix.host.targets
              scrape_interval = "15s"
              forward_to      = [prometheus.relabel.host.receiver]
            }

            prometheus.remote_write "beacon" {
              endpoint {
                name = "beacon"
                url  = "${cfg.prometheus.remoteWriteUrl}"
              }
            }
          ''
          ++ cfg.extraFragments
        )
      );
    in
    {
      options.dsqr.darwin.grafana.alloy = {
        enable = mkEnableOption "Grafana Alloy host monitoring";

        package = mkPackageOption pkgs "grafana-alloy" { };

        instance = mkOption {
          type = str;
          default = hostName;
          description = "Stable instance label for this host.";
        };

        role = mkOption {
          type = str;
          default = hostName;
          description = "Role label for this host.";
        };

        environment = mkOption {
          type = str;
          default = "homelab";
          description = "Environment label for this host.";
        };

        prometheus.remoteWriteUrl = mkOption {
          type = str;
          default = "http://10.10.30.102:9090/api/v1/write";
          description = "Prometheus remote_write receiver URL on beacon.";
        };

        extraFragments = mkOption {
          type = listOf lines;
          default = [ ];
          description = "Additional Alloy config appended after the generated base metrics pipeline.";
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = singleton cfg.package;

        system.activationScripts.preActivation.text = /* bash */ ''
          mkdir -p /var/lib/grafana-alloy
          mkdir -p /var/log/grafana-alloy
        '';

        launchd.daemons.grafana-alloy = {
          serviceConfig = {
            KeepAlive = true;
            RunAtLoad = true;
            WorkingDirectory = "/var/lib/grafana-alloy";
            StandardOutPath = "/var/log/grafana-alloy/alloy.log";
            StandardErrorPath = "/var/log/grafana-alloy/alloy.log";
            ProgramArguments = [
              "${cfg.package}/bin/alloy"
              "run"
              "--storage.path=/var/lib/grafana-alloy"
              "--server.http.listen-addr=127.0.0.1:12345"
              "${alloyConfig}"
            ];
          };
        };
      };
    };
}
