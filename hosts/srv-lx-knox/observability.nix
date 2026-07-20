_: {
  dsqr.nixos.alloy = {
    enable = true;
    loki.enable = true;
    prometheus = {
      enable = true;
      extraConfig = ''
        prometheus.scrape "postgres_exporter" {
          targets = [
            {
              __address__ = "127.0.0.1:9187",
              job         = "postgres-exporter",
              instance    = "srv-lx-knox",
              host        = "srv-lx-knox",
              role        = "postgresql",
              env         = "homelab",
            },
          ]
          scrape_interval = "15s"
          forward_to      = [prometheus.remote_write.primary.receiver]
        }
      '';
    };
  };
}
