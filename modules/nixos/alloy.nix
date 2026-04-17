{ config, lib, ... }:
let
  inherit (lib) mkForce mkIf optionalString;
  cfg = config.dsqr.nixos.alloy;
  k8sCfg = cfg.kubernetes;
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

    systemd.services.alloy.serviceConfig = lib.mkMerge [
      { SupplementaryGroups = lib.mkAfter (lib.optionals cfg.loki.enable [ "systemd-journal" ]); }
      (mkIf k8sCfg.enable {
        # Kubernetes API discovery needs kubeconfig access on the host. Running
        # Alloy as root on cluster nodes keeps the setup simple and avoids
        # managing a second kubeconfig copy just for the agent.
        DynamicUser = mkForce false;
        User = "root";
        Group = "root";
      })
    ];

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
    ''
    + optionalString cfg.loki.enable ''

      loki.write "beacon" {
        endpoint {
          url = "${cfg.loki.writeUrl}"
        }
      }

      loki.relabel "journal" {
        forward_to = [loki.write.beacon.receiver]

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
      }

      loki.source.journal "systemd" {
        forward_to    = [loki.write.beacon.receiver]
        relabel_rules = loki.relabel.journal.rules
        max_age       = "${cfg.loki.journalMaxAge}"

        labels = {
          "job"      = "systemd-journal",
          "instance" = "${cfg.instance}",
          "host"     = "${cfg.instance}",
          "role"     = "${cfg.role}",
          "env"      = "${cfg.environment}",
          "os"       = "linux",
        }
      }
    ''
    + optionalString (k8sCfg.enable && k8sCfg.kubeStateMetrics.enable) ''

      discovery.kubernetes "kube_state_metrics" {
        role            = "pod"
        kubeconfig_file = "${k8sCfg.kubeconfigFile}"

        namespaces {
          names = ["${k8sCfg.kubeStateMetrics.namespace}"]
        }

        selectors {
          role  = "pod"
          label = "${k8sCfg.kubeStateMetrics.labelSelector}"
        }
      }

      discovery.relabel "kube_state_metrics" {
        targets = discovery.kubernetes.kube_state_metrics.targets

        rule {
          source_labels = ["__meta_kubernetes_pod_container_port_number"]
          regex         = "${toString k8sCfg.kubeStateMetrics.port}"
          action        = "keep"
        }

        rule {
          target_label = "job"
          replacement  = "kube-state-metrics"
        }

        rule {
          target_label = "cluster"
          replacement  = "${k8sCfg.cluster}"
        }

        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label  = "namespace"
        }

        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label  = "pod"
        }

        rule {
          source_labels = ["__meta_kubernetes_pod_node_name"]
          target_label  = "node"
        }
      }

      prometheus.scrape "kube_state_metrics" {
        targets         = discovery.relabel.kube_state_metrics.output
        scrape_interval = "${k8sCfg.kubeStateMetrics.scrapeInterval}"
        forward_to      = [prometheus.remote_write.beacon.receiver]
      }
    ''
    + optionalString (cfg.extraConfig != "") ''

      ${cfg.extraConfig}
    '';
  };
}
