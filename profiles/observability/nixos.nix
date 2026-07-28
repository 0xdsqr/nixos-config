{ hostName, lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  dsqr.nixos.alloy = {
    enable = mkDefault true;
    environment = mkDefault "homelab";
    remoteWriteUrl = mkDefault (
      if hostName == "srv-lx-beacon" then "http://127.0.0.1:9090/api/v1/write" else "http://10.10.30.102:9090/api/v1/write"
    );

    kubernetes.cluster = mkDefault "hub-a";

    loki = {
      enable = mkDefault true;
      writeUrl = mkDefault (
        if hostName == "srv-lx-beacon" then
          "http://127.0.0.1:3100/loki/api/v1/push"
        else
          "http://10.10.30.102:3100/loki/api/v1/push"
      );
    };

    prometheus.enable = mkDefault true;
  };
}
