{
  flake.nixosModules."monitoring-alloy-base" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatStringsSep optionalString;
      inherit (lib.types) lines listOf str;
      cfg = config.dsqr.nixos.alloy;
      composedConfig = concatStringsSep "\n\n" cfg.configFragments;
    in
    {
      options.dsqr.nixos.alloy = {
        enable = mkEnableOption "Enable the shared Alloy monitoring baseline";

        instance = mkOption {
          type = str;
          default = config.networking.hostName;
          description = "Stable instance label for this host";
        };

        role = mkOption {
          type = str;
          default = config.networking.hostName;
          description = "Role label for this host";
        };

        environment = mkOption {
          type = str;
          default = "homelab";
          description = "Environment label for this host";
        };

        remoteWriteUrl = mkOption {
          type = str;
          default =
            if config.networking.hostName == "srv-lx-beacon" then
              "http://127.0.0.1:9090/api/v1/write"
            else
              "http://10.10.30.102:9090/api/v1/write";
          description = "Prometheus remote_write receiver URL on beacon";
        };

        extraConfig = mkOption {
          type = lines;
          default = "";
          description = "Deprecated compatibility shim for extra Alloy config. Prefer the Prometheus and Loki-specific hooks.";
        };

        configFragments = mkOption {
          type = listOf lines;
          default = [ ];
          internal = true;
          description = "Internal Alloy config fragments composed by the monitoring-* modules.";
        };
      };

      config = mkMerge [
        (mkIf cfg.enable {
          services.alloy = {
            enable = true;
            extraFlags = [
              "--server.http.listen-addr=127.0.0.1:12345"
              "--disable-reporting"
            ];
          };

          environment.etc."alloy/config.alloy".text =
            composedConfig
            + optionalString (cfg.extraConfig != "") ''

              ${cfg.extraConfig}
            '';

          dsqr.nixos.alloy.configFragments = mkAfter [
            ''
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
                  replacement  = "linux"
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
                  url  = "${cfg.remoteWriteUrl}"
                }
              }
            ''
          ];
        })

        (mkIf (cfg.extraConfig != "") {
          warnings = [
            "dsqr.nixos.alloy.extraConfig is deprecated; prefer dsqr.nixos.alloy.prometheus.extraConfig or dsqr.nixos.alloy.loki.extraConfig."
          ];
        })
      ];
    };
}
