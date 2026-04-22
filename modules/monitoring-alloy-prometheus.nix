{
  flake.nixosModules."monitoring-alloy-prometheus" =
    { config, lib, ... }:
    let
      inherit (lib)
        mkAfter
        mkForce
        mkIf
        optionalString
        ;
      cfg = config.dsqr.nixos.alloy;
      k8sCfg = cfg.kubernetes;
    in
    {
      config = mkIf cfg.enable {
        systemd.services.alloy.serviceConfig = mkIf k8sCfg.enable {
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
          )
        ];
      };
    };
}
