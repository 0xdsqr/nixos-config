{ lib, ... }:
let
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) filter remove;
  inherit (lib.strings) hasSuffix;
  nixFiles = filter (hasSuffix ".nix") (listFilesRecursive ./.);
in
{
  imports = remove ./meta.nix (remove ./default.nix nixFiles);

  services.restic.passwordAgeFile = ./restic.password.age;

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    proxmox.enable = true;

    alloy = {
      enable = true;
      remoteWriteUrl = "http://127.0.0.1:9090/api/v1/write";
      role = "beacon";
      loki = {
        enable = true;
        writeUrl = "http://127.0.0.1:3100/loki/api/v1/push";
      };
      extraConfig = ''
        loki.process "opnsense_syslog" {
          forward_to = [loki.write.beacon.receiver]

          stage.static_labels {
            values = {
              service_name = "opnsense"
            }
          }

          stage.match {
            selector = "{job=\"opnsense-syslog\", app=\"filterlog\"}"

            stage.regex {
              expression = "^[0-9]+,(?:[^,]*,){4}(?P<interface>[^,]+),(?P<match_reason>[^,]+),(?P<action>pass|block),(?P<direction>in|out),.*$"
            }

            stage.labels {
              values = {
                action    = ""
                direction = ""
              }
            }

            stage.structured_metadata {
              values = {
                interface    = ""
                match_reason = ""
              }
            }
          }
        }

        loki.relabel "opnsense_syslog" {
          forward_to = [loki.process.opnsense_syslog.receiver]

          rule {
            source_labels = ["__syslog_connection_ip_address"]
            target_label  = "sender_ip"
          }

          rule {
            source_labels = ["__syslog_message_hostname"]
            target_label  = "host"
          }

          rule {
            source_labels = ["__syslog_message_app_name"]
            target_label  = "app"
          }

          rule {
            source_labels = ["__syslog_message_severity"]
            target_label  = "severity"
          }

          rule {
            source_labels = ["__syslog_message_facility"]
            target_label  = "facility"
          }
        }

        loki.source.syslog "opnsense" {
          listener {
            address                = "0.0.0.0:1514"
            protocol               = "tcp"
            syslog_format          = "rfc5424"
            use_incoming_timestamp = true
            labels = {
              job    = "opnsense-syslog",
              env    = "homelab",
              source = "opnsense",
              role   = "firewall",
            }
          }

          forward_to    = [loki.write.beacon.receiver]
          relabel_rules = loki.relabel.opnsense_syslog.rules
        }
      '';
    };
  };

  networking.hostName = "beacon";
  networking.firewall.allowedTCPPorts = [
    8000
    9090
    3100
    1514
  ];
  networking.firewall.allowedUDPPorts = [ ];
  system.stateVersion = "25.05";
}
