{
  flake.nixosModules.kubeadm-encryption =
    { config, lib, pkgs, ... }:
    let
      inherit (lib) mkEnableOption mkOption mkIf;
      kubeadm = config.dsqr.nixos.kubeadm;
      cfg = kubeadm.encryption;
      sysusers = config.systemd.sysusers.enable || config.services.userborn.enable;
      directory = "/run/kubernetes-encryption";
      renderer = pkgs.writeShellApplication {
        name = "render-kubeadm-encryption";
        text = ''
          ulimit -c 0
          exec ${pkgs.nodejs}/bin/node ${../../packages/kubeadm-secrets}/render-config.mjs \
            ${lib.escapeShellArg config.age.secrets.kubeadm-encryption-keyring.path} \
            ${lib.escapeShellArg kubeadm.cluster.name} ${directory}
        '';
      };
    in
    {
      options.dsqr.nixos.kubeadm.encryption = {
        enable = mkEnableOption "staged, locally keyed Secrets encryption for kubeadm API servers";
        keyringFile = mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Age-encrypted cluster keyring; never a plaintext key or provider configuration.";
        };
        stage = mkOption {
          type = lib.types.enum [ "read-compatible" "encrypt" "enforced" ];
          default = "read-compatible";
          description = ''
            Start read-compatible on ALL API servers, then enable encrypt on each.
            Use enforced only after rewriting and verifying all stored Secrets.
            Stage changes require explicit API manifest regeneration; never remove
            decryption keys needed by live data or retained backups.
          '';
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = kubeadm.enable && kubeadm.role == "control-plane"
              && kubeadm.apiServerHardening.enable && kubeadm.cluster.name != null;
            message = "Secrets encryption requires a named, hardened kubeadm control plane.";
          }
          {
            assertion = cfg.keyringFile != null;
            message = "Secrets encryption requires an age-encrypted cluster keyring.";
          }
        ];

        age.secrets.kubeadm-encryption-keyring = {
          file = cfg.keyringFile;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        # Agenix runs during activation unless sysusers/userborn is enabled.
        # The boot/switch service below also covers that alternative ordering.
        system.activationScripts.kubeadmEncryption = mkIf (!sysusers) {
          deps = [ "agenix" ];
          text = "${lib.getExe renderer}";
        };

        systemd.services.kubeadm-encryption = {
          description = "Prepare private Kubernetes encryption provider configurations";
          wantedBy = [ "multi-user.target" ];
          before = [ "kubelet.service" ];
          after = lib.optional sysusers "agenix-install-secrets.service";
          requires = lib.optional sysusers "agenix-install-secrets.service";
          restartTriggers = [ cfg.keyringFile ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.getExe renderer;
            UMask = "0077";
            LimitCORE = 0;
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ directory ];
            RuntimeDirectory = "kubernetes-encryption";
            RuntimeDirectoryMode = "0700";
            # An old static manifest must remain restartable across switches.
            # Do not delete its provider file when this oneshot is restarted.
            RuntimeDirectoryPreserve = true;
          };
        };
        systemd.services.kubelet = {
          requires = [ "kubeadm-encryption.service" ];
          after = [ "kubeadm-encryption.service" ];
        };
      };
    };
}
