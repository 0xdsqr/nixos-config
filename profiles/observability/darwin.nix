{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  dsqr.darwin.grafana = {
    alloy = {
      environment = mkDefault "homelab";
      prometheus.remoteWriteUrl = mkDefault "http://10.10.30.102:9090/api/v1/write";
    };

    loki.writeUrl = mkDefault "http://10.10.30.102:3100/loki/api/v1/push";
  };
}
