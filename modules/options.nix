{
  flake.commonModules.options =
    { hostMeta, lib, ... }:
    let
      inherit (lib) mkOption types;
      hostProfiles = [
        "darwin-laptop-aarch64"
        "darwin-mini-aarch64"
        "linux-desktop-aarch64"
        "linux-desktop-x86_64"
        "linux-vm-aarch64"
        "linux-vm-x86_64"
      ];
      hostProfile =
        if hostMeta.profile != null then
          hostMeta.profile
        else if hostMeta.class == "darwin" then
          "darwin-laptop-aarch64"
        else
          "linux-vm-x86_64";
      defaultHomeProfile =
        if
          builtins.elem hostProfile [
            "darwin-mini-aarch64"
            "linux-vm-aarch64"
            "linux-vm-x86_64"
          ]
        then
          "server"
        else
          "desktop";
    in
    {
      options.dsqr.host.profile = mkOption {
        type = types.enum hostProfiles;
        default = hostProfile;
        description = "High-level host shape used to derive sane defaults for this machine.";
      };

      options.dsqr.home = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to attach the shared Home Manager profile for this host.";
        };

        profile = mkOption {
          type = types.enum [
            "desktop"
            "server"
          ];
          default = defaultHomeProfile;
          description = "Shared Home Manager profile to apply for this host.";
        };

        userName = mkOption {
          type = types.str;
          default = "dsqr";
          description = "Primary Home Manager user on NixOS hosts.";
        };

        imports = mkOption {
          type = types.listOf types.deferredModule;
          default = [ ];
          description = "Additional Home Manager modules merged into the primary user profile for this host.";
        };
      };
    };

  flake.darwinModules.options =
    { hostName, lib, ... }:
    let
      inherit (lib) mkEnableOption mkOption types;
    in
    {
      options.dsqr.darwin = {
        alloy = {
          enable = mkEnableOption "Enable Alloy-based host monitoring on Darwin hosts";

          instance = mkOption {
            type = types.str;
            default = hostName;
            description = "Stable instance label for this host";
          };

          remoteWriteUrl = mkOption {
            type = types.str;
            default = "http://10.10.30.102:9090/api/v1/write";
            description = "Prometheus remote_write receiver URL on beacon";
          };

          loki = {
            enable = mkEnableOption "Enable Loki log shipping through Alloy on Darwin hosts";

            writeUrl = mkOption {
              type = types.str;
              default = "http://10.10.30.102:3100/loki/api/v1/push";
              description = "Loki push endpoint on beacon";
            };
          };
        };

        devbox.enable = mkEnableOption "Devbox-specific Darwin settings";

        exo.enable = mkEnableOption "Exo-specific Darwin settings";
      };
    };

  flake.nixosModules.options =
    {
      config,
      keys,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        optionals
        types
        unique
        ;
      userCfg = config.dsqr.nixos.user;
    in
    {
      options.dsqr.nixos = {
        proxmox = {
          enable = mkEnableOption "Enable the shared Proxmox guest baseline";

          hostName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Hostname to apply when this host runs as a Proxmox VM.";
          };
        };

        user = {
          enable = mkEnableOption "Enable the shared dsqr/root account baseline";

          passwordAgeFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Encrypted age file that stores the shared password hash for dsqr and root.";
          };

          extraGroups = mkOption {
            type = types.listOf types.str;
            default = [
              "wheel"
              "networkmanager"
            ];
            description = "Additional groups granted to the dsqr user on this host.";
          };

          serverAdmin.enable = mkEnableOption "Grant dsqr the extra groups commonly needed for heavier server administration";
        };

        alloy = {
          enable = mkEnableOption "Enable Alloy-based host monitoring on NixOS hosts";

          instance = mkOption {
            type = types.str;
            default = config.networking.hostName;
            description = "Stable instance label for this host";
          };

          role = mkOption {
            type = types.str;
            default = config.networking.hostName;
            description = "Role label for this host";
          };

          environment = mkOption {
            type = types.str;
            default = "homelab";
            description = "Environment label for this host";
          };

          remoteWriteUrl = mkOption {
            type = types.str;
            default =
              if config.networking.hostName == "beacon" then
                "http://127.0.0.1:9090/api/v1/write"
              else
                "http://10.10.30.102:9090/api/v1/write";
            description = "Prometheus remote_write receiver URL on beacon";
          };

          prometheus.extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Additional Prometheus-related Alloy config appended to the shared metrics pipeline.";
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Deprecated compatibility shim for extra Alloy config. Prefer the Prometheus and Loki-specific hooks.";
          };

          loki = {
            enable = mkEnableOption "Enable Loki log shipping through Alloy on NixOS hosts";

            writeUrl = mkOption {
              type = types.str;
              default =
                if config.networking.hostName == "beacon" then
                  "http://127.0.0.1:3100/loki/api/v1/push"
                else
                  "http://10.10.30.102:3100/loki/api/v1/push";
              description = "Loki push endpoint on beacon";
            };

            journalMaxAge = mkOption {
              type = types.str;
              default = "24h";
              description = "How far back Alloy should read journald entries on startup.";
            };

            journalProcessStages = mkOption {
              type = types.lines;
              default = "";
              description = "Additional stages appended to the shared journald processing pipeline.";
            };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Additional Loki-related Alloy config appended after the shared journald pipeline.";
            };
          };

          kubernetes = {
            enable = mkEnableOption "Enable Kubernetes-aware Alloy scraping on this host";

            kubeconfigFile = mkOption {
              type = types.str;
              default = "/etc/kubernetes/admin.conf";
              description = "Kubeconfig file Alloy should use for Kubernetes API discovery.";
            };

            cluster = mkOption {
              type = types.str;
              default = "homelab";
              description = "Stable cluster label applied to Kubernetes metrics scraped by Alloy.";
            };

            kubeStateMetrics = {
              enable = mkEnableOption "Scrape kube-state-metrics through Alloy";

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

          configFragments = mkOption {
            type = types.listOf types.lines;
            default = [ ];
            internal = true;
            description = "Internal Alloy config fragments composed by the monitoring-* modules.";
          };

        };

        cloudflared = {
          enable = mkEnableOption "Run a remotely managed Cloudflare tunnel connector";

          tunnelId = mkOption {
            type = types.str;
            description = "Cloudflare tunnel ID managed outside Nix.";
          };

          tunnelName = mkOption {
            type = types.str;
            default = config.networking.hostName;
            description = "Friendly name used for the local Cloudflared service.";
          };

          tokenAgeFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Encrypted age file that stores the Cloudflare tunnel token.";
          };
        };

        containers = {
          enable = mkEnableOption "Enable the shared container runtime baseline";

          docker.enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Docker when the shared container runtime baseline is active.";
          };

          podman.enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Podman when the shared container runtime baseline is active.";
          };

          podman.dockerCompat = mkOption {
            type = types.bool;
            default = true;
            description = "Expose the Docker-compatible Podman CLI shim when Podman is enabled.";
          };

          podman.dockerSocket.enable = mkOption {
            type = types.bool;
            default = true;
            description = "Expose the Docker-compatible Podman socket when Podman is enabled.";
          };

          podman.defaultNetwork.dnsEnabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable DNS in the default Podman network when Podman is enabled.";
          };
        };

        postgresql = {
          enable = mkEnableOption "Enable the shared PostgreSQL host profile";

          ensure = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Databases and matching users to create automatically.";
          };

          listenAddresses = mkOption {
            type = types.listOf types.str;
            default = [
              "127.0.0.1"
              "::1"
            ];
            description = "PostgreSQL addresses to listen on when TCP is enabled.";
          };

          allowedCIDRs = mkOption {
            type = types.listOf types.str;
            default = [
              "127.0.0.1/32"
              "::1/128"
            ];
            description = "CIDRs allowed to authenticate over TCP.";
          };

          hostAuthMethod = mkOption {
            type = types.enum [
              "md5"
              "scram-sha-256"
            ];
            default = "md5";
            description = "Password auth method for TCP clients. Keep md5 until all role passwords are rotated to SCRAM.";
          };

          exporter.listenAddress = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Address the postgres Prometheus exporter listens on.";
          };

        };

        redis = {
          enable = mkEnableOption "Enable the shared Redis host profile";

          passwordAgeFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Encrypted age file that stores the Redis password.";
          };
        };

        kubeadm = {
          enable = mkEnableOption "Enable the shared kubeadm baseline";

          helm.enable = mkOption {
            type = types.bool;
            default = true;
            description = "Install the Helm CLI alongside the kubeadm baseline.";
          };
        };

        rustfs = {
          enable = mkEnableOption "Enable the shared RustFS host profile";

          accessKeyAgeFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Encrypted age file that stores the RustFS access key.";
          };

          secretKeyAgeFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Encrypted age file that stores the RustFS secret key.";
          };
        };
      };

      config = mkIf (userCfg.enable && userCfg.passwordAgeFile != null) {
        age.secrets.hostPassword.file = userCfg.passwordAgeFile;

        users.users.dsqr = {
          isNormalUser = true;
          home = "/home/dsqr";
          description = "its me dave";
          hashedPasswordFile = config.age.secrets.hostPassword.path;
          extraGroups = unique (
            userCfg.extraGroups
            ++ optionals userCfg.serverAdmin.enable [
              "docker"
              "lxd"
            ]
          );
          openssh.authorizedKeys.keys = keys.admins;
        };

        users.users.root.hashedPasswordFile = config.age.secrets.hostPassword.path;
      };
    };
}
