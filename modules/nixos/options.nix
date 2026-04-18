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
      enable = mkEnableOption "Enable Proxmox-based host leveraging NixOS";
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
        description = "Prometheus remote_write receiver URL on beacon";
      };

      loki = {
        enable = mkEnableOption "Enable Loki log shipping through Alloy on NixOS hosts";

        writeUrl = mkOption {
          type = types.str;
          description = "Loki push endpoint on beacon";
        };

        journalMaxAge = mkOption {
          type = types.str;
          default = "24h";
          description = "How far back Alloy should read journald entries on startup.";
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

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional Alloy configuration appended to the default host monitoring pipeline.";
      };
    };

    postgresql = {
      enable = mkEnableOption "Enable the shared PostgreSQL host profile";

      ensure = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Databases and matching users to create automatically.";
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
}
