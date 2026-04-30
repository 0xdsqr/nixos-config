{
  flake.nixosModules.rustfs =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs' nameValuePair;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) nullOr package path;
      cfg = config.dsqr.nixos.rustfs;
      resticHosts = config.services.restic.hosts or [ ];
    in
    {
      imports = [ inputs.rustfs.nixosModules.rustfs ];

      options.dsqr.nixos.rustfs = {
        enable = mkEnableOption "Enable RustFS";

        package = mkOption {
          type = package;
          inherit (inputs.rustfs.packages.${config.nixpkgs.hostPlatform.system}) default;
          defaultText = "inputs.rustfs.packages.${config.nixpkgs.hostPlatform.system}.default";
          description = "RustFS package to run.";
        };

        accessKeyAgeFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Encrypted age file that stores the RustFS access key.";
        };

        secretKeyAgeFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Encrypted age file that stores the RustFS secret key.";
        };
      };

      config = mkIf (cfg.enable && cfg.accessKeyAgeFile != null && cfg.secretKeyAgeFile != null) {
        age.secrets.rustfsAccessKey = {
          file = cfg.accessKeyAgeFile;
          mode = "0400";
        };

        age.secrets.rustfsSecretKey = {
          file = cfg.secretKeyAgeFile;
          mode = "0400";
        };

        networking.firewall.allowedTCPPorts = [
          9000
          9001
        ];

        services.rustfs = {
          enable = true;
          inherit (cfg) package;
          accessKeyFile = config.age.secrets.rustfsAccessKey.path;
          secretKeyFile = config.age.secrets.rustfsSecretKey.path;
          volumes = [ "/var/lib/rustfs/data" ];
          address = "0.0.0.0:9000";
          consoleEnable = true;
          consoleAddress = "0.0.0.0:9001";
          logLevel = "warn";
          logDirectory = "/var/log/rustfs";
        };

        services.restic.backups = mkIf (resticHosts != [ ]) (
          genAttrs' resticHosts (
            host:
            let
              hostBackup = config.services.restic.backups.${host};
            in
            nameValuePair "rustfs-${host}" {
              repository = "sftp:backup@${host}:${config.networking.hostName}-rustfs-backup";
              inherit (hostBackup) passwordFile;
              inherit (hostBackup) initialize;
              inherit (hostBackup) extraOptions;
              inherit (hostBackup) pruneOpts;
              inherit (hostBackup) timerConfig;

              paths = [ "/var/lib/rustfs/data" ];

              backupPrepareCommand = ''
                systemctl stop rustfs.service
              '';

              backupCleanupCommand = ''
                systemctl start rustfs.service
              '';
            }
          )
        );

        warnings = [
          ''
            RustFS is currently wired for a single local data path at /var/lib/rustfs/data.
            Upstream recommends XFS on dedicated JBOD disks for serious use; switch RUSTFS_VOLUMES and
            host mounts before treating this as a production deployment.
          ''
        ];
      };
    };
}
