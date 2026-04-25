{
  config,
  pkgs,
  lib,
  ...
}:
let
  mailDomain = "dsqr.dev";
  mailHost = "mx.${mailDomain}";
  stalwartIdentifier = config.services.stalwart.user;
  runtimeConfigPath = "/run/${stalwartIdentifier}/stalwart.toml";
  stalwartSettings = {
    server.hostname = mailHost;

    tracer.journal.enable = false;
    tracer.stdout = {
      type = "stdout";
      level = "info";
      ansi = false;
      enable = true;
    };

    certificate.default = {
      cert = "%{file:${config.security.acme.certs.${mailHost}.directory}/fullchain.pem}%";
      private-key = "%{file:${config.security.acme.certs.${mailHost}.directory}/key.pem}%";
    };

    server.tls = {
      certificate = "default";
      enable = true;
      implicit = false;
    };

    server.listener = {
      smtp = {
        bind = [ "[::]:25" ];
        protocol = "smtp";
      };

      submission = {
        bind = [ "[::]:587" ];
        protocol = "smtp";
      };

      submissions = {
        bind = [ "[::]:465" ];
        protocol = "smtp";
        tls.implicit = true;
      };

      imaps = {
        bind = [ "[::]:993" ];
        protocol = "imap";
        tls.implicit = true;
      };

      http = {
        bind = [ "[::]:80" ];
        protocol = "http";
      };

      https = {
        bind = [ "[::]:443" ];
        protocol = "http";
        tls.implicit = true;
      };
    };

    store.db = {
      type = "rocksdb";
      path = "${config.services.stalwart.dataDir}/db";
      compression = "lz4";
    };

    storage = {
      data = "db";
      fts = "db";
      lookup = "db";
      blob = "db";
      directory = "memory";
    };

    resolver = {
      type = "system";
      public-suffix = [ "file://${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat" ];
    };

    spam-filter.resource = "file://${config.services.stalwart.package.spam-filter}/spam-filter.toml";

    webadmin = {
      path = "/var/cache/${stalwartIdentifier}";
      resource = "file://${config.services.stalwart.package.webadmin}/webadmin.zip";
    };

    session.auth.directory = "'memory'";
    session.auth.mechanisms = "[plain, login]";
    session.rcpt.directory = "'memory'";

    authentication.fallback-admin = {
      user = "admin";
      secret = "%{file:/run/credentials/stalwart.service/admin_secret}%";
    };

    queue.strategy.route = [
      {
        "if" = "is_local_domain('', rcpt_domain)";
        "then" = "'local'";
      }
      { "else" = "'relay'"; }
    ];

    queue.route.local.type = "local";
    queue.route.relay = {
      type = "relay";
      address = "email-smtp.us-east-1.amazonaws.com";
      port = 587;
      protocol = "smtp";
      auth = {
        username = "__SES_SMTP_USERNAME__";
        secret = "__SES_SMTP_PASSWORD__";
      };
      tls = {
        implicit = false;
        "allow-invalid-certs" = false;
      };
    };

    directory.memory = {
      type = "memory";
      principals = [
        {
          class = "domain";
          name = mailDomain;
          description = "Primary mail domain";
        }
        {
          name = "me";
          class = "individual";
          description = "Dave";
          secret = "__MAIL_ME_PASSWORD__";
          email = [
            "me@dsqr.dev"
            "m@dsqr.dev"
            "dave@dsqr.dev"
            "david@dsqr.dev"
            "postmaster@dsqr.dev"
            "abuse@dsqr.dev"
          ];
        }
        {
          name = "admin";
          class = "individual";
          description = "Admin";
          secret = "__MAIL_ADMIN_PASSWORD__";
          email = [ "admin@dsqr.dev" ];
        }
        {
          name = "hoo";
          class = "individual";
          description = "Hoo";
          secret = "__MAIL_HOO_PASSWORD__";
          email = [ "hoo@dsqr.dev" ];
        }
      ];
    };
  };
  stalwartTemplate = (pkgs.formats.toml { }).generate "stalwart-runtime-template.toml" stalwartSettings;
in
{
  age.secrets.cloudflareAcmeEnv.file = ./cloudflare-acme.env.age;
  age.secrets.sesSmtpPassword.file = ./ses-smtp.password.age;
  age.secrets.sesSmtpUsername.file = ./ses-smtp.username.age;
  age.secrets.stalwartAdminSecret.file = ./stalwart-admin.secret.age;
  age.secrets.stalwartAdminPassword.file = ./stalwart-admin.password.age;
  age.secrets.stalwartMePassword.file = ./stalwart-me.password.age;
  age.secrets.stalwartHooPassword.file = ./stalwart-hoo.password.age;

  security.acme = {
    acceptTerms = true;
    defaults.email = "me@dsqr.dev";
    certs.${mailHost} = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflareAcmeEnv.path;
      group = "stalwart";
    };
  };

  services.stalwart = {
    enable = true;
    stateVersion = "26.05";
    openFirewall = true;

    credentials = {
      admin_secret = config.age.secrets.stalwartAdminSecret.path;
      ses_smtp_password = config.age.secrets.sesSmtpPassword.path;
      ses_smtp_username = config.age.secrets.sesSmtpUsername.path;
      mail_admin_password = config.age.secrets.stalwartAdminPassword.path;
      mail_me_password = config.age.secrets.stalwartMePassword.path;
      mail_hoo_password = config.age.secrets.stalwartHooPassword.path;
    };

    settings = stalwartSettings;
  };

  systemd.services.stalwart = {
    preStart = lib.mkAfter ''
            cp ${stalwartTemplate} ${runtimeConfigPath}
            chmod 0600 ${runtimeConfigPath}

            ${pkgs.python3}/bin/python <<'PY'
      from pathlib import Path

      config_path = Path("${runtimeConfigPath}")
      config_text = config_path.read_text()
      config_text = config_text.replace(
          "__MAIL_ADMIN_PASSWORD__",
          Path("/run/credentials/stalwart.service/mail_admin_password").read_text().rstrip("\n"),
      )
      config_text = config_text.replace(
          "__SES_SMTP_USERNAME__",
          Path("/run/credentials/stalwart.service/ses_smtp_username").read_text().rstrip("\n"),
      )
      config_text = config_text.replace(
          "__SES_SMTP_PASSWORD__",
          Path("/run/credentials/stalwart.service/ses_smtp_password").read_text().rstrip("\n"),
      )
      config_text = config_text.replace(
          "__MAIL_ME_PASSWORD__",
          Path("/run/credentials/stalwart.service/mail_me_password").read_text().rstrip("\n"),
      )
      config_text = config_text.replace(
          "__MAIL_HOO_PASSWORD__",
          Path("/run/credentials/stalwart.service/mail_hoo_password").read_text().rstrip("\n"),
      )
      config_path.write_text(config_text)
      PY
    '';

    serviceConfig = {
      RuntimeDirectory = stalwartIdentifier;
      RuntimeDirectoryMode = "0700";
      ExecStart = lib.mkForce [
        ""
        "${lib.getExe config.services.stalwart.package} --config=${runtimeConfigPath}"
      ];
    };
  };
}
