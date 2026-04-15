_: {
  services.grafana.provision.dashboards.settings = {
    apiVersion = 1;
    providers = [
      {
        name = "homelab";
        folder = "Homelab";
        type = "file";
        disableDeletion = false;
        updateIntervalSeconds = 30;
        options.path = ./dashboards/homelab;
      }
    ];
  };
}
