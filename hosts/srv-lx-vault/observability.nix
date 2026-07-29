_: {
  dsqr.nixos.alloy.prometheus.extraConfig = ''
    prometheus.scrape "vault" {
      targets = [
        {
          __address__ = "127.0.0.1:8202",
          job         = "vault",
          instance    = "srv-lx-vault",
          host        = "srv-lx-vault",
          role        = "vault",
          env         = "homelab",
        },
      ]
      metrics_path    = "/v1/sys/metrics"
      scrape_interval = "15s"
      params = {
        format = ["prometheus"],
      }
      forward_to = [prometheus.remote_write.primary.receiver]
    }
  '';
}
