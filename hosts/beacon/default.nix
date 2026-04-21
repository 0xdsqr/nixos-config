{ dtil, ... }:
{
  imports = dtil.modules.collectNix {
    dir = ./.;
    ignoredNames = [ "meta.nix" ];
  };

  services.restic.passwordAgeFile = ./restic.password.age;

  dsqr.nixos = {
    user = {
      enable = true;
      passwordAgeFile = ./host.password.age;
      serverAdmin.enable = true;
    };

    # this host runs as a proxmox vm; enable the shared guest baseline
    # for grub boot, qemu guest agent, cloud-init disablement, and dhcp defaults.
    proxmox = {
      enable = true;
      hostName = "beacon";
    };

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
              job          = "opnsense-syslog",
              env          = "homelab",
              source       = "opnsense",
              role         = "firewall",
              service_name = "opnsense",
            }
          }

          forward_to    = [loki.write.beacon.receiver]
          relabel_rules = loki.relabel.opnsense_syslog.rules
        }
      '';
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      8000
      9090
      3100
      1514
    ];
  };

  system.stateVersion = "25.05";
}
