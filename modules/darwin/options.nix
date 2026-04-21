{
  hostName,
  lib,
  pkgs,
  ...
}:
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

    builder = {
      enable = mkEnableOption "Enable this Darwin host as a remote builder";

      sshUser = mkOption {
        type = types.str;
        default = "dsqr";
        description = "SSH user clients should use for remote builds on this host.";
      };

      maxJobs = mkOption {
        type = types.int;
        default = 6;
        description = "Maximum concurrent jobs this builder should advertise.";
      };

      speedFactor = mkOption {
        type = types.int;
        default = 1;
        description = "Relative speed hint for this builder.";
      };

      supportedFeatures = mkOption {
        type = types.listOf types.str;
        default = [ "big-parallel" ];
        description = "Optional Nix builder features exposed by this host.";
      };

      systems = mkOption {
        type = types.listOf types.str;
        default = [ pkgs.stdenv.hostPlatform.system ];
        description = "System types this builder can execute.";
      };
    };

    devbox.enable = mkEnableOption "Devbox-specific Darwin settings";

    exo.enable = mkEnableOption "Exo-specific Darwin settings";
  };
}
