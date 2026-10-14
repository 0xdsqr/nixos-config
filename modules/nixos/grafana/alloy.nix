{
  flake.nixosModules."monitoring-alloy-base" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAfter mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) concatStringsSep optionalString;
      inherit (lib.types)
        lines
        listOf
        nullOr
        str
        submodule
        ;
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
          default = "default";
          description = "Environment label for this host";
        };

        remoteWriteUrl = mkOption {
          type = nullOr str;
          default = null;
          description = "Prometheus remote_write receiver URL.";
        };

        clientTls = mkOption {
          type = nullOr (submodule {
            options = {
              caFile = mkOption {
                type = str;
                default = "/etc/ssl/certs/ca-certificates.crt";
                description = "CA bundle verifying the telemetry server.";
              };
              certificateFile = mkOption {
                type = str;
                description = "Runtime client certificate chain; never an inline private key.";
              };
              privateKeyFile = mkOption {
                type = str;
                description = "Runtime client private key readable only by the collector.";
              };
            };
          });
          default = null;
          description = "Optional verified client TLS for the shared metrics and Loki endpoints.";
        };

        clientTlsConfig = mkOption {
          type = lines;
          internal = true;
          readOnly = true;
          default = optionalString (cfg.clientTls != null) ''
            tls_config {
              ca_file = ${builtins.toJSON cfg.clientTls.caFile}
              cert_file = ${builtins.toJSON cfg.clientTls.certificateFile}
              key_file = ${builtins.toJSON cfg.clientTls.privateKeyFile}
              insecure_skip_verify = false
              min_version = "TLS12"
            }
          '';
        };

        hostCluster = mkOption {
          type = nullOr str;
          default = null;
          description = "Optional cluster label for this host's OS metrics and journals.";
        };

        systemdUnitInclude = mkOption {
          type = str;
          default = "(alloy|caddy|cloudflared|grafana|loki|postgresql|prometheus|restic-backups-.+|rustfs|stalwart|tempo|temporal|vault|vault-agent-.+)\\.service";
          description = "Systemd unit regex monitored by the shared host exporter.";
        };

        remoteWriteMaxSampleAge = mkOption {
          type = nullOr str;
          default = null;
          description = "Optional maximum age of queued metrics to send; older samples are dropped.";
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
          assertions = [
            {
              assertion = cfg.remoteWriteUrl != null;
              message = "dsqr.nixos.alloy.remoteWriteUrl must be set when dsqr.nixos.alloy.enable is true.";
            }
            {
              assertion =
                cfg.clientTls == null || lib.hasPrefix "https://" (if cfg.remoteWriteUrl == null then "" else cfg.remoteWriteUrl);
              message = "Alloy client TLS requires an HTTPS remoteWriteUrl.";
            }
          ];

          services.alloy = {
            enable = true;
            extraFlags = [
              "--server.http.listen-addr=127.0.0.1:12345"
              "--stability.level=experimental"
              "--disable-reporting"
            ];
          };

          environment.etc."alloy/config.alloy".text =
            composedConfig
            + optionalString (cfg.extraConfig != "") ''

              ${cfg.extraConfig}
            '';

          systemd.tmpfiles.rules = [ "d /var/lib/alloy/textfile 0755 root root - -" ];

          dsqr.nixos.alloy.configFragments = mkAfter [
            ''
              prometheus.exporter.unix "host" {
                enable_collectors = ["systemd"]

                systemd {
                  enable_restarts = true
                  start_time      = true
                  unit_include    = ${builtins.toJSON cfg.systemdUnitInclude}
                }

                textfile {
                  directory = "/var/lib/alloy/textfile"
                }
              }

              prometheus.relabel "host" {
                forward_to = [prometheus.remote_write.primary.receiver]

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

                ${optionalString (cfg.hostCluster != null) ''
                  rule {
                    target_label = "cluster"
                    replacement = ${builtins.toJSON cfg.hostCluster}
                  }
                ''}
              }

              prometheus.scrape "host" {
                targets         = prometheus.exporter.unix.host.targets
                scrape_interval = "15s"
                forward_to      = [prometheus.relabel.host.receiver]
              }

              prometheus.remote_write "primary" {
                endpoint {
                  name = "primary"
                  url  = "${if cfg.remoteWriteUrl == null then "" else cfg.remoteWriteUrl}"
                  ${cfg.clientTlsConfig}
                  ${optionalString (cfg.clientTls != null) "follow_redirects = false"}
                  ${optionalString (cfg.remoteWriteMaxSampleAge != null) ''
                    queue_config {
                      sample_age_limit = ${builtins.toJSON cfg.remoteWriteMaxSampleAge}
                    }
                  ''}
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
