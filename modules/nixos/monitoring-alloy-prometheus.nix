{
  flake.nixosModules."monitoring-alloy-prometheus" =
    { config, lib, ... }:
    let
      inherit (lib)
        mkAfter
        mkForce
        mkIf
        mkOption
        optionalString
        types
        ;
      cfg = config.dsqr.nixos.alloy;
      k8sCfg = cfg.kubernetes;
    in
    {
      options.dsqr.nixos.alloy = {
        prometheus.extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Additional Prometheus-related Alloy config appended to the shared metrics pipeline.";
        };

        kubernetes = {
          kubeconfigFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Kubeconfig file Alloy should use for Kubernetes API discovery. Leave null on non-Kubernetes hosts.";
          };

          cluster = mkOption {
            type = types.str;
            default = "homelab";
            description = "Stable cluster label applied to Kubernetes metrics scraped by Alloy.";
          };

          kubeStateMetrics = {
            namespace = mkOption {
              type = types.str;
              default = "kube-system";
              description = "Namespace where kube-state-metrics runs.";
            };

            labelSelector = mkOption {
              type = types.str;
              default = "app.kubernetes.io/name=kube-state-metrics";
              description = "Kubernetes label selector used to discover kube-state-metrics pods.";
            };

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Metrics port exposed by kube-state-metrics.";
            };

            scrapeInterval = mkOption {
              type = types.str;
              default = "30s";
              description = "Scrape interval for kube-state-metrics.";
            };
          };
        };
      };

      config = {
        systemd.services.alloy.serviceConfig = mkIf (k8sCfg.kubeconfigFile != null) {
          # Kubernetes API discovery needs kubeconfig access on the host. Running
          # Alloy as root on cluster nodes keeps the setup simple and avoids
          # managing a second kubeconfig copy just for the agent.
          DynamicUser = mkForce false;
          User = "root";
          Group = "root";
        };

        dsqr.nixos.alloy.configFragments = mkAfter [
          (
            cfg.prometheus.extraConfig
            + optionalString (k8sCfg.kubeconfigFile != null) ''

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
          )
        ];
      };
    };
}
