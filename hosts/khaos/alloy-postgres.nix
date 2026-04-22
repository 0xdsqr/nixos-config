_: {
  dsqr.nixos.alloy.prometheus.extraConfig = ''
    prometheus.scrape "postgres_exporter" {
      targets = [
        {
          __address__ = "127.0.0.1:9187",
          job         = "postgres-exporter",
          instance    = "khaos",
          host        = "khaos",
          role        = "khaos",
          env         = "homelab",
        },
      ]
      scrape_interval = "15s"
      forward_to      = [prometheus.remote_write.beacon.receiver]
    }
  '';
}
