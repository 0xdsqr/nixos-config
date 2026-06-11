{ config, ... }:
let
  metrics = {
    listenAddress = "127.0.0.1";
    port = 8000;
  };
in
{
  dsqr.nixos.alloy.prometheus.extraConfig = ''
    prometheus.scrape "temporal" {
      targets = [
        {
          __address__ = "${metrics.listenAddress}:${toString metrics.port}",
          job         = "temporal",
          instance    = "${config.networking.hostName}",
          host        = "${config.networking.hostName}",
          role        = "${config.networking.hostName}",
          env         = "homelab",
        },
      ]
      scrape_interval = "15s"
      forward_to      = [prometheus.remote_write.primary.receiver]
    }
  '';
}
