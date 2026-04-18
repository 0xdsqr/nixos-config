{ config, lib, ... }:
let
  inherit (lib) genAttrs;
  port = 8000;
in
{
  age.secrets.grafanaPassword = {
    file = ./grafana.admin.password.age;
    owner = "grafana";
  };

  age.secrets.grafanaDbPassword = {
    file = ./grafana.database.password.age;
    owner = "grafana";
  };

  age.secrets.grafanaSecretKey = {
    file = ./grafana.secret-key.age;
    owner = "grafana";
  };

  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ "/var/lib/grafana" ];
  });

  services.grafana = {
    enable = true;
    openFirewall = false;

    settings = {
      analytics.reporting_enabled = false;

      database = {
        type = "postgres";
        host = "192.168.50.71:5432";
        name = "grafana";
        user = "grafana";
        password = "$__file{${config.age.secrets.grafanaDbPassword.path}}";
        ssl_mode = "disable";
      };

      # server.domain    = fqdn;
      server.http_addr = "0.0.0.0";
      server.http_port = port;

      users.default_theme = "system";
    };

    settings.security = {
      # admin_email = "";
      admin_password = "$__file{${config.age.secrets.grafanaPassword.path}}";
      admin_user = "admin";
      secret_key = "$__file{${config.age.secrets.grafanaSecretKey.path}}";

      # cookie_secure = true; # Re-enable once Grafana is served over HTTPS.
      disable_gravatar = true;

      # disable_initial_admin_creation = false;
    };
  };
}
