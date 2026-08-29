{
  flake.nixosModules.kubeadm =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib.lists) optionals;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        bool
        enum
        nullOr
        package
        port
        str
        ;

      cfg = config.dsqr.nixos.kubeadm;

      yaml = pkgs.formats.yaml { };

      renderYaml =
        name: value:
        let
          source = yaml.generate "${name}.source" value;
        in
        pkgs.runCommand name { } ''
          ${pkgs.gnused}/bin/sed '/^%YAML /d' ${source} > "$out"
        '';

      kubeadmConfig = renderYaml "kubeadm-init.yaml" {
        apiVersion = "kubeadm.k8s.io/v1beta4";
        kind = "InitConfiguration";
        localAPIEndpoint = {
          advertiseAddress = cfg.nodeAddress;
          bindPort = cfg.cluster.apiPort;
        };
        nodeRegistration = {
          criSocket = "unix:///run/containerd/containerd.sock";
          kubeletExtraArgs = [
            {
              name = "node-ip";
              value = cfg.nodeAddress;
            }
          ];
          name = config.networking.hostName;
        };
        timeouts.controlPlaneComponentHealthCheck = "4m0s";
      };

      kubeadmClusterConfig = renderYaml "kubeadm-cluster.yaml" {
        apiServer.certSANs = [ cfg.cluster.apiVip ];
        apiVersion = "kubeadm.k8s.io/v1beta4";
        clusterName = cfg.cluster.name;
        controlPlaneEndpoint = cfg.cluster.apiEndpoint;
        kind = "ClusterConfiguration";
        kubernetesVersion = "v${lib.getVersion cfg.packages.kubernetes}";
        networking = {
          dnsDomain = cfg.cluster.dnsDomain;
          podSubnet = cfg.cluster.podSubnet;
          serviceSubnet = cfg.cluster.serviceSubnet;
        };
        proxy.disabled = cfg.cluster.disableKubeProxy;
      };

      kubeletConfig = renderYaml "kubelet.yaml" {
        apiVersion = "kubelet.config.k8s.io/v1beta1";
        cgroupDriver = "systemd";
        kind = "KubeletConfiguration";
      };

      kubeVipManifest =
        kubeconfig:
        renderYaml "kube-vip.yaml" {
          apiVersion = "v1";
          kind = "Pod";
          metadata = {
            name = "kube-vip";
            namespace = "kube-system";
          };
          spec = {
            containers = [
              {
                args = [ "manager" ];
                env = [
                  {
                    name = "vip_arp";
                    value = "true";
                  }
                  {
                    name = "port";
                    value = toString cfg.cluster.apiPort;
                  }
                  {
                    name = "vip_nodename";
                    valueFrom.fieldRef.fieldPath = "spec.nodeName";
                  }
                  {
                    name = "vip_interface";
                    value = cfg.kubeVip.interface;
                  }
                  {
                    name = "vip_subnet";
                    value = "32";
                  }
                  {
                    name = "cp_enable";
                    value = "true";
                  }
                  {
                    name = "cp_namespace";
                    value = "kube-system";
                  }
                  {
                    name = "vip_leaderelection";
                    value = "true";
                  }
                  {
                    name = "vip_leasename";
                    value = "kube-vip-${cfg.cluster.name}-control-plane";
                  }
                  {
                    name = "vip_leaseduration";
                    value = "15";
                  }
                  {
                    name = "vip_renewdeadline";
                    value = "10";
                  }
                  {
                    name = "vip_retryperiod";
                    value = "2";
                  }
                  {
                    name = "address";
                    value = cfg.cluster.apiVip;
                  }
                  {
                    name = "prometheus_server";
                    value = "";
                  }
                ];
                image = "ghcr.io/kube-vip/kube-vip:${cfg.kubeVip.version}";
                imagePullPolicy = "IfNotPresent";
                name = "kube-vip";
                securityContext.capabilities = {
                  add = [
                    "NET_ADMIN"
                    "NET_RAW"
                  ];
                  drop = [ "ALL" ];
                };
                volumeMounts = [
                  {
                    mountPath = "/etc/kubernetes/admin.conf";
                    name = "kubeconfig";
                    readOnly = true;
                  }
                ];
              }
            ];
            hostAliases = [
              {
                hostnames = [ "kubernetes" ];
                ip = "127.0.0.1";
              }
            ];
            hostNetwork = true;
            priorityClassName = "system-node-critical";
            volumes = [
              {
                hostPath = {
                  path = kubeconfig;
                  type = "File";
                };
                name = "kubeconfig";
              }
            ];
          };
        };
    in
    {
      options.dsqr.nixos.kubeadm = {
        enable = mkEnableOption "Enable the shared kubeadm node baseline";

        role = mkOption {
          type = nullOr (enum [
            "control-plane"
            "worker"
          ]);
          default = null;
          description = "Kubernetes role assigned to this node.";
        };

        nodeAddress = mkOption {
          type = nullOr str;
          default = null;
          description = "Stable address advertised by this Kubernetes node.";
        };

        bootstrap = mkOption {
          type = bool;
          default = false;
          description = "Whether this node initializes the cluster control plane.";
        };

        cluster = {
          name = mkOption {
            type = nullOr str;
            default = null;
            description = "Stable name of the Kubernetes cluster.";
          };

          apiEndpoint = mkOption {
            type = nullOr str;
            default = null;
            description = "Stable host and port used to reach the Kubernetes API.";
          };

          apiVip = mkOption {
            type = nullOr str;
            default = null;
            description = "Virtual IPv4 address advertised for the Kubernetes API.";
          };

          apiPort = mkOption {
            type = port;
            default = 6443;
            description = "Port exposed by the Kubernetes API.";
          };

          dnsDomain = mkOption {
            type = str;
            default = "cluster.local";
            description = "DNS domain used inside the Kubernetes cluster.";
          };

          podSubnet = mkOption {
            type = nullOr str;
            default = null;
            description = "CIDR allocated to Kubernetes pods.";
          };

          serviceSubnet = mkOption {
            type = nullOr str;
            default = null;
            description = "CIDR allocated to Kubernetes services.";
          };

          disableKubeProxy = mkOption {
            type = bool;
            default = false;
            description = "Disable kube-proxy so a replacement such as Cilium can own service routing.";
          };
        };

        kubeVip = {
          enable = mkEnableOption "kube-vip control-plane high availability";

          interface = mkOption {
            type = nullOr str;
            default = null;
            description = "Host interface on which kube-vip advertises the API VIP.";
          };

          version = mkOption {
            type = str;
            default = "v1.2.3";
            description = "Pinned kube-vip container image version.";
          };
        };

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
        assertions = [
          {
            assertion = cfg.role == null || cfg.nodeAddress != null;
            message = "dsqr.nixos.kubeadm.nodeAddress must be set for role-aware Kubernetes nodes.";
          }
          {
            assertion = cfg.role == null || cfg.cluster.name != null;
            message = "dsqr.nixos.kubeadm.cluster.name must be set for role-aware Kubernetes nodes.";
          }
          {
            assertion = cfg.role == null || cfg.cluster.apiEndpoint != null;
            message = "dsqr.nixos.kubeadm.cluster.apiEndpoint must be set for role-aware Kubernetes nodes.";
          }
          {
            assertion = !cfg.bootstrap || cfg.cluster.podSubnet != null;
            message = "A bootstrap Kubernetes node requires dsqr.nixos.kubeadm.cluster.podSubnet.";
          }
          {
            assertion = !cfg.bootstrap || cfg.cluster.serviceSubnet != null;
            message = "A bootstrap Kubernetes node requires dsqr.nixos.kubeadm.cluster.serviceSubnet.";
          }
          {
            assertion = !cfg.bootstrap || cfg.cluster.apiVip != null;
            message = "A bootstrap Kubernetes node requires dsqr.nixos.kubeadm.cluster.apiVip.";
          }
          {
            assertion = !cfg.bootstrap || cfg.role == "control-plane";
            message = "Only a Kubernetes control-plane node may bootstrap a cluster.";
          }
          {
            assertion = !cfg.kubeVip.enable || cfg.role == "control-plane";
            message = "kube-vip may only be enabled on Kubernetes control-plane nodes.";
          }
          {
            assertion = !cfg.kubeVip.enable || cfg.cluster.apiVip != null;
            message = "kube-vip requires dsqr.nixos.kubeadm.cluster.apiVip.";
          }
          {
            assertion = !cfg.kubeVip.enable || cfg.kubeVip.interface != null;
            message = "kube-vip requires dsqr.nixos.kubeadm.kubeVip.interface.";
          }
        ];

        environment.etc = {
          "default/kubelet" = mkIf (cfg.nodeAddress != null) { text = "KUBELET_EXTRA_ARGS=--node-ip=${cfg.nodeAddress}"; };

          "kubernetes/kubeadm/init.yaml" = mkIf cfg.bootstrap {
            source = pkgs.concatText "kubeadm-init.yaml" [
              kubeadmConfig
              kubeadmClusterConfig
              kubeletConfig
            ];
          };

          "kubernetes/kube-vip/bootstrap.yaml" = mkIf (cfg.kubeVip.enable && cfg.bootstrap) {
            source = kubeVipManifest "/etc/kubernetes/super-admin.conf";
          };

          "kubernetes/kube-vip/steady.yaml" = mkIf cfg.kubeVip.enable { source = kubeVipManifest "/etc/kubernetes/admin.conf"; };
        };

        networking.firewall = {
          allowedTCPPorts = [
            10250
            4240
            7946
          ]
          ++ optionals (cfg.role == "control-plane") [
            2379
            2380
            6443
            10257
            10259
          ];
          allowedUDPPorts = [
            7946
            8472
          ];
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
