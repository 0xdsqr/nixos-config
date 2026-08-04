{
  flake.nixosModules.rustfs =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.modules) mkForce mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        bool
        nullOr
        package
        path
        str
        ;
      cfg = config.dsqr.nixos.rustfs;
      resticHosts = config.services.restic.hosts or [ ];
    in
    {
      # nixpkgs now ships a RustFS module with a different interface. This
      # wrapper intentionally uses rustfs-flake's module and package together.
      disabledModules = [ "services/web-servers/rustfs.nix" ];
      imports = [ inputs.rustfs.nixosModules.rustfs ];

      options.dsqr.nixos.rustfs = {
        enable = mkEnableOption "Enable RustFS";

        package = mkOption {
          type = package;
          inherit (inputs.rustfs.packages.${config.nixpkgs.hostPlatform.system}) default;
          defaultText = "inputs.rustfs.packages.${config.nixpkgs.hostPlatform.system}.default";
          description = "RustFS package to run.";
        };

        address = mkOption {
          type = str;
          default = ":9000";
          description = "Address used by the S3-compatible API listener.";
        };

        consoleAddress = mkOption {
          type = str;
          default = ":9001";
          description = "Address used by the management console listener.";
        };

        openFirewall = mkOption {
          type = bool;
          default = false;
          description = "Open the RustFS API and console ports to every source.";
        };

        tlsDirectory = mkOption {
          type = nullOr str;
          default = null;
          description = "Runtime directory containing rustfs_cert.pem and rustfs_key.pem.";
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

        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          9000
          9001
        ];

        services.rustfs = {
          enable = true;
          inherit (cfg) package address consoleAddress;
          accessKeyFile = config.age.secrets.rustfsAccessKey.path;
          secretKeyFile = config.age.secrets.rustfsSecretKey.path;
          volumes = [ "/var/lib/rustfs/data" ];
          consoleEnable = true;
          logLevel = "warn";
          logDirectory = null;
        }
        // lib.optionalAttrs (cfg.tlsDirectory != null) {
          inherit (cfg) tlsDirectory;
          extraEnvironmentVariables.RUSTFS_TLS_PATH = cfg.tlsDirectory;
        };

        services.restic.backups = mkIf (resticHosts != [ ]) (
          genAttrs resticHosts (host: {
            repository = mkForce "sftp:backup@${host}:${config.networking.hostName}-rustfs-backup";
            paths = [ "/var/lib/rustfs/data" ];

            backupPrepareCommand = ''
              systemctl stop rustfs.service
            '';

            backupCleanupCommand = ''
              systemctl start rustfs.service
            '';
          })
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
