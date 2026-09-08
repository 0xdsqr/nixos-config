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
      inherit (lib.modules) mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        bool
        enum
        listOf
        nullOr
        package
        port
        str
        ;

      cfg = config.dsqr.nixos.kubeadm;

      ipv4Address = lib.types.strMatching "([0-9]{1,3}\\.){3}[0-9]{1,3}";
      ipv4Subnet = lib.types.strMatching "([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])";
      firewallSources = values: lib.concatStringsSep ", " (lib.unique values);

      # This is host-input filtering, not a replacement for pod network policy.
      # Pod-to-node requests can arrive with their pod IP or a node SNAT address
      # (observed for Indigo Metrics Server), so retain both explicit sources.
      nodeFirewallRules = ''
        ip saddr { ${
          firewallSources (cfg.nodeFirewall.nodeAddresses ++ cfg.nodeFirewall.podSubnets)
        } } tcp dport { 4240, 10250 } counter accept comment "Kubernetes kubelet and Cilium health peers"
        ip saddr { ${firewallSources cfg.nodeFirewall.nodeAddresses} } udp dport 8472 counter accept comment "Cilium VXLAN node peers"
      ''
      + lib.optionalString (cfg.role == "control-plane") ''
        ip saddr { ${firewallSources cfg.nodeFirewall.controlPlaneAddresses} } tcp dport { 2379, 2380 } counter accept comment "Stacked etcd control-plane peers"
      ''
      + lib.optionalString (builtins.elem cfg.nodeAddress cfg.nodeFirewall.memberlistAddresses) ''
        ip saddr { ${firewallSources cfg.nodeFirewall.memberlistAddresses} } tcp dport 7946 counter accept comment "MetalLB memberlist peers"
        ip saddr { ${firewallSources cfg.nodeFirewall.memberlistAddresses} } udp dport 7946 counter accept comment "MetalLB memberlist peers"
      '';

      # Used only by nodes explicitly opted into routingCompatibility below.
      # Include the proxy return path through Cilium's internal devices, without
      # trusting entire interfaces or opening dynamic proxy ports to the LAN.
      ciliumProxyRoutingRules = ''
        iifname "lxc*" meta mark & 0x00000f00 == 0x00000200 counter accept comment "Cilium endpoint policy proxy"
        iifname { "cilium_host", "cilium_net", "cilium_vxlan" } meta mark & 0x00000f00 == 0x00000200 counter accept comment "Cilium internal policy proxy"
      '';

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
        serverTLSBootstrap = cfg.kubelet.serverTlsBootstrap;
      };

      reconcileKubeletServerTlsBootstrap = pkgs.writeShellApplication {
        name = "reconcile-kubelet-server-tls-bootstrap";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.yq-go
        ];
        text = ''
          config=/var/lib/kubelet/config.yaml

          # kubeadm materializes this file outside the Nix store. Reconcile the
          # field before every kubelet start so joins and kubeadm upgrades cannot
          # silently restore self-signed serving certificates.
          if [[ ! -f "$config" ]]; then
            exit 0
          fi

          temporary="$(mktemp --tmpdir=/var/lib/kubelet .config.yaml.XXXXXX)"
          trap 'rm -f "$temporary"' EXIT
          yq eval '.serverTLSBootstrap = true' "$config" > "$temporary"
          chown --reference="$config" "$temporary"
          chmod --reference="$config" "$temporary"

          if cmp --silent "$config" "$temporary"; then
            exit 0
          fi

          mv "$temporary" "$config"
          trap - EXIT
        '';
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

        ciliumProxyFirewall.enable = mkEnableOption "Allow Cilium-marked proxy traffic through the native nftables host firewall";

        ciliumProxyFirewall.routingCompatibility.enable = mkEnableOption ''
          Opt this node into interface-scoped Cilium veth proxy routing compatibility.
          Requires Cilium SourceIPVerification; roll out per node after validation
        '';

        nodeFirewall = {
          enable = mkEnableOption "Restrict Kubernetes internal host ports to explicit IPv4 peers";

          nodeAddresses = mkOption {
            type = listOf ipv4Address;
            default = [ ];
            description = "All cluster node IPv4 addresses, including this node; used for VXLAN, health and SNATed kubelet requests.";
          };

          controlPlaneAddresses = mkOption {
            type = listOf ipv4Address;
            default = [ ];
            description = "Stacked-etcd control-plane IPv4 addresses; only these peers receive etcd access.";
          };

          memberlistAddresses = mkOption {
            type = listOf ipv4Address;
            default = [ ];
            description = "MetalLB speaker IPv4 addresses. Memberlist is opened only on nodes in this list.";
          };

          podSubnets = mkOption {
            type = listOf ipv4Subnet;
            default = [ ];
            description = "Cluster pod IPv4 CIDRs allowed to reach kubelet and Cilium health; pod policy remains a separate layer.";
          };
        };

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

        kubelet.serverTlsBootstrap = mkOption {
          type = bool;
          default = false;
          description = "Request rotating kubelet serving certificates from the cluster CA.";
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
            assertion =
              !cfg.nodeFirewall.enable
              || (
                config.networking.firewall.enable
                && config.networking.nftables.enable
                && cfg.role != null
                && builtins.elem cfg.nodeAddress cfg.nodeFirewall.nodeAddresses
                && cfg.nodeFirewall.podSubnets != [ ]
                && cfg.nodeFirewall.controlPlaneAddresses != [ ]
                && lib.all (address: builtins.elem address cfg.nodeFirewall.nodeAddresses) (
                  cfg.nodeFirewall.controlPlaneAddresses ++ cfg.nodeFirewall.memberlistAddresses
                )
                && (
                  cfg.role != "control-plane" || builtins.elem cfg.nodeAddress cfg.nodeFirewall.controlPlaneAddresses
                )
              );
            message = "Restricted Kubernetes node firewall requires native nftables, a node role, this node in nodeAddresses, podSubnets, and control-plane/memberlist peers drawn from nodeAddresses.";
          }
          {
            assertion =
              !cfg.ciliumProxyFirewall.routingCompatibility.enable
              || (cfg.ciliumProxyFirewall.enable && config.networking.nftables.enable);
            message = "Cilium proxy routing compatibility requires ciliumProxyFirewall.enable and the native nftables firewall.";
          }
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
          "default/kubelet" = mkIf (cfg.nodeAddress != null) {
            text = "KUBELET_EXTRA_ARGS=--node-ip=${cfg.nodeAddress}";
          };

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

          "kubernetes/kube-vip/steady.yaml" = mkIf cfg.kubeVip.enable {
            source = kubeVipManifest "/etc/kubernetes/admin.conf";
          };
        };

        networking.firewall = {
          # Cilium's CILIUM_INPUT accept in iptables-nft does not bypass a
          # separate nftables base chain. Mirror its to-proxy mark/mask here
          # so redirected DNS/L7 traffic reaches the local policy proxy.
          # This is a kernel packet mark, not an externally supplied IP field;
          # it does not open the proxy's dynamic port to ordinary host traffic.
          extraInputRules = mkMerge [
            (mkIf (cfg.ciliumProxyFirewall.enable && config.networking.nftables.enable) (
              if cfg.ciliumProxyFirewall.routingCompatibility.enable then
                ciliumProxyRoutingRules
              else
                ''
                  meta mark & 0x00000f00 == 0x00000200 counter accept comment "Cilium policy proxy traffic"
                ''
            ))
            (mkIf cfg.nodeFirewall.enable nodeFirewallRules)
          ];

          # TPROXY policy-routes these marked packets to a local socket before
          # input. The normal reverse-path lookup rejects that local route,
          # so preserve Cilium's to-proxy traffic at this earlier hook too.
          # Keep reverse-path filtering enabled for all unmarked traffic and
          # retain the existing behavior on nodes not explicitly opted in.
          extraReversePathFilterRules = mkIf cfg.ciliumProxyFirewall.routingCompatibility.enable ciliumProxyRoutingRules;

          allowedTCPPorts =
            optionals (!cfg.nodeFirewall.enable) [
              10250
              4240
              7946
            ]
            # Keep existing API client access until its separate access review.
            # SSH and trusted Tailscale interfaces are owned by their own modules.
            ++ optionals (cfg.role == "control-plane" && cfg.nodeFirewall.enable) [ cfg.cluster.apiPort ]
            ++ optionals (cfg.role == "control-plane" && !cfg.nodeFirewall.enable) [
              2379
              2380
              6443
              10257
              10259
            ];
          allowedUDPPorts = optionals (!cfg.nodeFirewall.enable) [
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

          # Tailscale sets global src_valid_mark. Cilium's marked TPROXY lookup
          # can then classify legitimate pod sources as local, even when
          # rp_filter=0. Scope accept_local to Cilium endpoint veths only; keep
          # Cilium SourceIPVerification enabled and leave LAN/Tailscale/global
          # settings untouched. Cilium owns accept_local on its cilium_* links.
          # systemd-sysctl applies this glob at activation/boot and the standard
          # udev rule reapplies it when new endpoint interfaces appear.
          "net.ipv4.conf.lxc*.accept_local" = mkIf cfg.ciliumProxyFirewall.routingCompatibility.enable 1;
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
          preStart = mkIf cfg.kubelet.serverTlsBootstrap "${lib.getExe reconcileKubeletServerTlsBootstrap}";

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
