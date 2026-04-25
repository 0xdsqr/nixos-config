{
  flake.nixosModules.kubeadm =
    { pkgs, ... }:

    let
      k8s = pkgs.kubernetes;
    in
    {
      config = {
        networking.firewall = {
          allowedTCPPorts = [
            10250
            4240
          ];
          allowedUDPPorts = [ 8472 ];
        };

        boot.kernelModules = [
          "overlay"
          "br_netfilter"
        ];

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.bridge.bridge-nf-call-iptables" = 1;
          "net.bridge.bridge-nf-call-ip6tables" = 1;
        };

        swapDevices = [ ];

        environment.systemPackages = with pkgs; [
          k8s
          cri-tools
          cni-plugins
          conntrack-tools
          ethtool
          socat
          iproute2
          iptables
        ];

        virtualisation.containerd = {
          enable = true;
          settings = {
            version = 2;
            plugins."io.containerd.grpc.v1.cri" = {
              cni = {
                bin_dir = "/opt/cni/bin";
                conf_dir = "/etc/cni/net.d";
              };
              containerd = {
                default_runtime_name = "runc";
                runtimes.runc = {
                  runtime_type = "io.containerd.runc.v2";
                  options.SystemdCgroup = true;
                };
              };
            };
          };
        };

        systemd.tmpfiles.rules = [ "d /var/lib/kubelet 0755 root root -" ];

        systemd.services.kubelet = {
          description = "Kubernetes Kubelet";
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.util-linux ];
          unitConfig.ConditionPathExists = "/var/lib/kubelet/config.yaml";
          unitConfig.ConditionPathExistsGlob = "/etc/kubernetes/*kubelet.conf";
          after = [
            "network-online.target"
            "containerd.service"
          ];
          wants = [
            "network-online.target"
            "containerd.service"
          ];

          serviceConfig = {
            Environment = [
              "KUBELET_KUBEADM_ARGS="
              "KUBELET_EXTRA_ARGS="
            ];
            EnvironmentFile = [
              "-/var/lib/kubelet/kubeadm-flags.env"
              "-/etc/default/kubelet"
            ];
            Restart = "always";
            RestartSec = 5;
            ExecStart = "${k8s}/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS";
          };
        };
      };
    };
}
