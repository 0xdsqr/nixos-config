{
  flake.nixosModules.kubeadm =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.nixos.kubeadm;
    in
    {
      options.dsqr.nixos.kubeadm = {
        enable = mkEnableOption "Enable the shared kubeadm node baseline";

        packages = {
          kubernetes = mkOption {
            type = package;
            default = pkgs.kubernetes;
            defaultText = "pkgs.kubernetes";
            description = "Kubernetes package providing kubeadm and kubelet.";
          };

          criTools = mkOption {
            type = package;
            default = pkgs.cri-tools;
            defaultText = "pkgs.cri-tools";
            description = "CRI command line tools package.";
          };

          cniPlugins = mkOption {
            type = package;
            default = pkgs.cni-plugins;
            defaultText = "pkgs.cni-plugins";
            description = "CNI plugins package.";
          };

          conntrackTools = mkOption {
            type = package;
            default = pkgs.conntrack-tools;
            defaultText = "pkgs.conntrack-tools";
            description = "conntrack tools package.";
          };

          ethtool = mkOption {
            type = package;
            default = pkgs.ethtool;
            defaultText = "pkgs.ethtool";
            description = "ethtool package.";
          };

          socat = mkOption {
            type = package;
            default = pkgs.socat;
            defaultText = "pkgs.socat";
            description = "socat package.";
          };

          iproute2 = mkOption {
            type = package;
            default = pkgs.iproute2;
            defaultText = "pkgs.iproute2";
            description = "iproute2 package.";
          };

          iptables = mkOption {
            type = package;
            default = pkgs.iptables;
            defaultText = "pkgs.iptables";
            description = "iptables package.";
          };

          util-linux = mkOption {
            type = package;
            default = pkgs.util-linux;
            defaultText = "pkgs.util-linux";
            description = "util-linux package used by kubelet.";
          };
        };
      };

      config = mkIf cfg.enable {
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

        environment.systemPackages = [
          cfg.packages.kubernetes
          cfg.packages.criTools
          cfg.packages.cniPlugins
          cfg.packages.conntrackTools
          cfg.packages.ethtool
          cfg.packages.socat
          cfg.packages.iproute2
          cfg.packages.iptables
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
          path = [ cfg.packages.util-linux ];
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
            ExecStart = "${cfg.packages.kubernetes}/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS";
          };
        };
      };
    };
}
