{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.dsqr.nixos.alloy;
in
{
  config = mkIf cfg.enable {
    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=127.0.0.1:12345"
        "--disable-reporting"
      ];
    };

    environment.etc."alloy/config.alloy".text = ''
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
    '';
  };
}
