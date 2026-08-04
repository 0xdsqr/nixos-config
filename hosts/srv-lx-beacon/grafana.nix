{ config, ... }:
let
  fqdn = "grafana.home.arpa";
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

  services.grafana = {
    enable = true;
    openFirewall = false;
    provision = {
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "beacon";
            type = "file";
            disableDeletion = false;
            allowUiUpdates = false;
            updateIntervalSeconds = 30;
            options.path = ./grafana-dashboards;
            options.foldersFromFilesStructure = true;
          }
        ];
      };
    };

    settings = {
      analytics = {
        check_for_plugin_updates = false;
        check_for_updates = false;
        feedback_links_enabled = false;
        reporting_enabled = false;
      };

      "auth.anonymous".enabled = false;

      database = {
        type = "postgres";
        host = "postgres.service.home.arpa:5432";
        name = "grafana";
        user = "grafana";
        password = "$__file{${config.age.secrets.grafanaDbPassword.path}}";
        ssl_mode = "verify-full";
        ca_cert_path = "/etc/ssl/certs/ca-certificates.crt";
        server_cert_name = "postgres.service.home.arpa";
      };

      server = {
        domain = fqdn;
        http_addr = "10.10.30.102";
        http_port = port;
        enforce_domain = true;
        root_url = "https://${fqdn}/";
      };

      snapshots = {
        external_enabled = false;
        public_mode = false;
      };

      users = {
        allow_org_create = false;
        allow_sign_up = false;
        default_theme = "system";
      };
    };

    settings.security = {
      # admin_email = "";
      admin_password = "$__file{${config.age.secrets.grafanaPassword.path}}";
      admin_user = "admin";
      secret_key = "$__file{${config.age.secrets.grafanaSecretKey.path}}";

      cookie_secure = true;
      cookie_samesite = "strict";
      disable_brute_force_login_protection = false;
      disable_gravatar = true;
      strict_transport_security = true;
      strict_transport_security_max_age_seconds = 31536000;

      # disable_initial_admin_creation = false;
    };
  };

  systemd.services.grafana = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
