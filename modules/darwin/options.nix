{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.dsqr.darwin = {
    alloy = {
      enable = mkEnableOption "Enable Alloy-based host monitoring on Darwin hosts";

      instance = mkOption {
        type = types.str;
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
}
