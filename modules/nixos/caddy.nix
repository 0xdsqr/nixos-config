{
  flake.nixosModules.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        mapAttrs
        mapAttrs'
        mapAttrsToList
        nameValuePair
        ;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.strings) concatStringsSep optionalString;
      inherit (lib.types)
        attrsOf
        bool
        int
        lines
        listOf
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.nixos.caddy;
      certificateCfg = cfg.certificate;
      vaultPkiCfg = cfg.vaultPkiCertificate;
      internalSourceRanges = concatStringsSep " " cfg.allowedSourceRanges;
      configuredStaticCertificate = certificateCfg.certFile != null && certificateCfg.keyFile != null;
      routeCertificateEnabled = configuredStaticCertificate || vaultPkiCfg.useForRoutes;
      routeCertFile = if configuredStaticCertificate then certificateCfg.certFile else vaultPkiCfg.certFile;
      routeKeyFile = if configuredStaticCertificate then certificateCfg.keyFile else vaultPkiCfg.keyFile;
      routeTlsDirective = if routeCertificateEnabled then "tls ${routeCertFile} ${routeKeyFile}" else "tls internal";
      vaultPkiAltNames = concatStringsSep "," vaultPkiCfg.altNames;
      vaultPkiRenewScript = pkgs.writeShellApplication {
        name = "caddy-renew-vault-pki-certificate";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.jq
          pkgs.openssl
          pkgs.systemd
        ];
        text = ''
          set -euo pipefail

          vault_addr='${vaultPkiCfg.vaultAddr}'
          auth_path='${vaultPkiCfg.authPath}'
          issue_path='${vaultPkiCfg.issuePath}'
          env_file='${vaultPkiCfg.environmentFile}'
          cert_dir='${vaultPkiCfg.certDirectory}'
          cert_file='${vaultPkiCfg.certFile}'
          key_file='${vaultPkiCfg.keyFile}'
          request_fingerprint_file="$cert_dir/request.sha256"
          common_name='${vaultPkiCfg.commonName}'
          alt_names='${vaultPkiAltNames}'
          ttl='${vaultPkiCfg.ttl}'
          renew_before_seconds='${toString vaultPkiCfg.renewBeforeSeconds}'

          request_fingerprint="$(
            printf '%s\0' "$vault_addr" "$auth_path" "$issue_path" "$common_name" "$alt_names" "$ttl" \
              | sha256sum \
              | cut -d ' ' -f 1
          )"

          certificate_covers_requested_names() {
            openssl x509 -checkhost "$common_name" -noout -in "$cert_file" >/dev/null || return 1

            if [ -n "$alt_names" ]; then
              while IFS= read -r alt_name; do
                openssl x509 -checkhost "$alt_name" -noout -in "$cert_file" >/dev/null || return 1
              done < <(printf '%s' "$alt_names" | tr ',' '\n')
            fi
          }

          if [ -s "$cert_file" ] \
            && [ -s "$key_file" ] \
            && [ -s "$request_fingerprint_file" ] \
            && [ "$(<"$request_fingerprint_file")" = "$request_fingerprint" ] \
            && openssl x509 -checkend "$renew_before_seconds" -noout -in "$cert_file" >/dev/null \
            && certificate_covers_requested_names; then
            echo "Caddy Vault PKI certificate is still valid."
            exit 0
          fi

          if [ ! -r "$env_file" ]; then
            echo "Missing readable Vault AppRole environment file: $env_file" >&2
            echo "Create it with VAULT_ROLE_ID and VAULT_SECRET_ID before applying this Caddy certificate config." >&2
            exit 1
          fi

          set -a
          # shellcheck source=/dev/null
          . "$env_file"
          set +a

          : "''${VAULT_ROLE_ID:?VAULT_ROLE_ID is required in $env_file}"
          : "''${VAULT_SECRET_ID:?VAULT_SECRET_ID is required in $env_file}"

          install -d -o caddy -g caddy -m 0750 "$cert_dir"

          token=""
          work_dir=""
          cleanup() {
            if [ -n "$token" ]; then
              curl -fsS \
                --request POST \
                --header "X-Vault-Token: $token" \
                "$vault_addr/v1/auth/token/revoke-self" >/dev/null || true
            fi

            if [ -n "$work_dir" ]; then
              rm -rf "$work_dir"
            fi
          }
          trap cleanup EXIT

          login_payload="$(
            jq -nc \
              --arg role_id "$VAULT_ROLE_ID" \
              --arg secret_id "$VAULT_SECRET_ID" \
              '{ role_id: $role_id, secret_id: $secret_id }'
          )"

          login_response="$(
            curl -fsS \
              --request POST \
              --header 'Content-Type: application/json' \
              --data "$login_payload" \
              "$vault_addr/v1/$auth_path"
          )"
          token="$(printf '%s' "$login_response" | jq -er '.auth.client_token')"

          issue_payload="$(
            jq -nc \
              --arg common_name "$common_name" \
              --arg alt_names "$alt_names" \
              --arg ttl "$ttl" \
              '{ common_name: $common_name, ttl: $ttl } + (if $alt_names == "" then {} else { alt_names: $alt_names } end)'
          )"

          issue_response="$(
            curl -fsS \
              --request POST \
              --header "X-Vault-Token: $token" \
              --header 'Content-Type: application/json' \
              --data "$issue_payload" \
              "$vault_addr/v1/$issue_path"
          )"

          work_dir="$(mktemp -d "$cert_dir/.renew.XXXXXX")"
          printf '%s' "$issue_response" | jq -er '.data.private_key' > "$work_dir/key.pem"
          printf '%s' "$issue_response" | jq -er '.data.certificate, .data.issuing_ca' > "$work_dir/fullchain.pem"

          chmod 0600 "$work_dir/key.pem"
          chmod 0644 "$work_dir/fullchain.pem"
          openssl x509 -checkhost "$common_name" -noout -in "$work_dir/fullchain.pem" >/dev/null
          if [ -n "$alt_names" ]; then
            while IFS= read -r alt_name; do
              openssl x509 -checkhost "$alt_name" -noout -in "$work_dir/fullchain.pem" >/dev/null
            done < <(printf '%s' "$alt_names" | tr ',' '\n')
          fi
          printf '%s\n' "$request_fingerprint" > "$work_dir/request.sha256"

          install -o caddy -g caddy -m 0640 "$work_dir/key.pem" "$key_file"
          install -o caddy -g caddy -m 0644 "$work_dir/fullchain.pem" "$cert_file"
          install -o caddy -g caddy -m 0644 "$work_dir/request.sha256" "$request_fingerprint_file"

          if systemctl -q is-active caddy.service; then
            systemctl reload caddy.service || systemctl restart caddy.service
          fi
        '';
      };

      mkReverseProxy =
        route:
        let
          hasHostHeader = route.hostHeader != null;
          hasTransportConfig = route.tlsInsecureSkipVerify || route.tlsServerName != null;
        in
        if !hasHostHeader && !hasTransportConfig then
          "reverse_proxy ${route.upstream}"
        else
          ''
            reverse_proxy ${route.upstream} {
              ${optionalString hasHostHeader "header_up Host ${route.hostHeader}"}
              ${optionalString hasTransportConfig ''
                transport http {
                  ${optionalString (route.tlsServerName != null) "tls_server_name ${route.tlsServerName}"}
                  ${optionalString route.tlsInsecureSkipVerify "tls_insecure_skip_verify"}
                }
              ''}
            }
          '';

      mkVirtualHost = _hostName: route: {
        extraConfig = ''
          ${optionalString route.tlsInternal routeTlsDirective}
          encode zstd gzip

          @internal remote_ip ${internalSourceRanges}
          handle @internal {
            ${mkReverseProxy route}
          }

          respond 403
          ${route.extraConfig}
        '';
      };

      mkHttpVirtualHost =
        hostName: route:
        let
          pathMatcher =
            if route.pathRegexp == null then "path ${concatStringsSep " " route.paths}" else "path_regexp ${route.pathRegexp}";
          reverseProxy =
            if route.tlsServerName == null then
              "reverse_proxy ${route.upstream}"
            else
              ''
                reverse_proxy ${route.upstream} {
                  transport http {
                    tls_server_name ${route.tlsServerName}
                  }
                }
              '';
        in
        nameValuePair "http://${hostName}" {
          extraConfig = ''
            @internal remote_ip ${internalSourceRanges}
            @httpRoutePath {
              ${pathMatcher}
            }

            handle @internal {
              handle @httpRoutePath {
                ${reverseProxy}
              }

              respond 404
            }

            respond 403
            ${route.extraConfig}
          '';
        };
    in
    {
      options.dsqr.nixos.caddy = {
        enable = mkEnableOption "Enable the shared Caddy reverse proxy baseline";

        package = mkPackageOption pkgs "caddy" { };

        openFirewall = mkOption {
          type = bool;
          default = true;
          description = "Open HTTP and HTTPS on the host firewall for Caddy.";
        };

        allowedSourceRanges = mkOption {
          type = listOf str;
          default = [
            "127.0.0.0/8"
            "::1/128"
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "100.64.0.0/10"
            "fc00::/7"
            "fe80::/10"
          ];
          description = "CIDR ranges allowed to use Caddy internal routes.";
        };

        routes = mkOption {
          type = attrsOf (submodule {
            options = {
              upstream = mkOption {
                type = str;
                description = "HTTP upstream target for this virtual host.";
                example = "http://10.10.30.102:8000";
              };

              tlsInternal = mkOption {
                type = bool;
                default = true;
                description = "Use Caddy's internal CA for this route during bootstrap.";
              };

              extraConfig = mkOption {
                type = lines;
                default = "";
                description = "Extra Caddyfile directives appended to this virtual host.";
              };

              hostHeader = mkOption {
                type = nullOr str;
                default = null;
                description = "Optional Host header sent to the upstream.";
                example = "argocd.home.arpa";
              };

              tlsServerName = mkOption {
                type = nullOr str;
                default = null;
                description = "Optional SNI server name used for HTTPS upstreams.";
                example = "argocd.home.arpa";
              };

              tlsInsecureSkipVerify = mkOption {
                type = bool;
                default = false;
                description = "Skip upstream TLS certificate verification for private HTTPS upstreams.";
              };
            };
          });
          default = { };
          description = "Internal hostnames and their reverse proxy upstreams.";
        };

        httpRoutes = mkOption {
          type = attrsOf (submodule {
            options = {
              upstream = mkOption {
                type = str;
                description = "HTTP upstream target for this plain HTTP virtual host.";
                example = "http://10.10.30.107:8200";
              };

              paths = mkOption {
                type = listOf str;
                default = [ ];
                description = "Literal Caddy path matchers to expose over plain HTTP.";
                example = [
                  "/.well-known/acme-challenge/*"
                  "/v1/pki_int/ocsp"
                ];
              };

              pathRegexp = mkOption {
                type = nullOr str;
                default = null;
                description = "Optional Caddy path_regexp matcher to expose over plain HTTP.";
                example = "^/v1/pki_int/(issuer/[^/]+/(der|crl/der)|ocsp)$";
              };

              tlsServerName = mkOption {
                type = nullOr str;
                default = null;
                description = "Optional SNI server name used for an HTTPS upstream.";
                example = "vault.service.home.arpa";
              };

              extraConfig = mkOption {
                type = lines;
                default = "";
                description = "Extra Caddyfile directives appended to this plain HTTP virtual host.";
              };
            };
          });
          default = { };
          description = "Plain HTTP routes for public-but-scoped endpoints such as PKI AIA, CRL, and OCSP distribution.";
        };

        certificate = {
          certFile = mkOption {
            type = nullOr str;
            default = null;
            description = "Optional static certificate file used by TLS-enabled internal routes.";
            example = "/var/lib/caddy/vault-pki/home-arpa/fullchain.pem";
          };

          keyFile = mkOption {
            type = nullOr str;
            default = null;
            description = "Optional static private key file used by TLS-enabled internal routes.";
            example = "/var/lib/caddy/vault-pki/home-arpa/key.pem";
          };
        };

        vaultPkiCertificate = {
          enable = mkEnableOption "Renew a Caddy certificate from Vault PKI";

          useForRoutes = mkOption {
            type = bool;
            default = false;
            description = "Use the Vault-issued certificate for TLS-enabled internal routes.";
          };

          vaultAddr = mkOption {
            type = str;
            default = "http://127.0.0.1:8200";
            description = "Vault API address used by the certificate renewal service.";
          };

          environmentFile = mkOption {
            type = str;
            default = "/var/lib/caddy/vault-pki.env";
            description = "Runtime-only environment file containing VAULT_ROLE_ID and VAULT_SECRET_ID.";
          };

          authPath = mkOption {
            type = str;
            default = "auth/approle/login";
            description = "Vault AppRole login API path without the /v1 prefix.";
          };

          issuePath = mkOption {
            type = str;
            default = "pki_int/issue/home-arpa";
            description = "Vault PKI issue API path without the /v1 prefix.";
          };

          commonName = mkOption {
            type = str;
            default = "*.home.arpa";
            description = "Certificate common name requested from Vault PKI.";
          };

          altNames = mkOption {
            type = listOf str;
            default = [ ];
            description = "Additional DNS names requested from Vault PKI.";
          };

          ttl = mkOption {
            type = str;
            default = "720h";
            description = "Certificate TTL requested from Vault PKI.";
          };

          renewBeforeSeconds = mkOption {
            type = int;
            default = 604800;
            description = "Renew when the current certificate expires within this many seconds.";
          };

          certDirectory = mkOption {
            type = str;
            default = "/var/lib/caddy/vault-pki/home-arpa";
            description = "Directory where the renewed certificate and key are written.";
          };

          certFile = mkOption {
            type = str;
            default = "/var/lib/caddy/vault-pki/home-arpa/fullchain.pem";
            description = "Full chain certificate path written by the Vault PKI renewal service.";
          };

          keyFile = mkOption {
            type = str;
            default = "/var/lib/caddy/vault-pki/home-arpa/key.pem";
            description = "Private key path written by the Vault PKI renewal service.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions =
          mapAttrsToList (hostName: route: {
            assertion = route.pathRegexp != null || route.paths != [ ];
            message = "dsqr.nixos.caddy.httpRoutes.${hostName} must set paths or pathRegexp.";
          }) cfg.httpRoutes
          ++ [
            {
              assertion = (certificateCfg.certFile == null) == (certificateCfg.keyFile == null);
              message = "dsqr.nixos.caddy.certificate.certFile and keyFile must be set together.";
            }
            {
              assertion = !vaultPkiCfg.useForRoutes || vaultPkiCfg.enable;
              message = "dsqr.nixos.caddy.vaultPkiCertificate.useForRoutes requires vaultPkiCertificate.enable.";
            }
          ];

        services.caddy = {
          enable = true;
          inherit (cfg) package;
          virtualHosts = mapAttrs mkVirtualHost cfg.routes // mapAttrs' mkHttpVirtualHost cfg.httpRoutes;
        };

        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          80
          443
        ];

        system.activationScripts.caddyVaultPkiCertificate = mkIf (vaultPkiCfg.enable && vaultPkiCfg.useForRoutes) {
          deps = [
            "groups"
            "users"
          ];
          text = ''
            echo "validating Caddy Vault PKI certificate"
            ${lib.getExe vaultPkiRenewScript}
          '';
        };

        systemd.tmpfiles.rules = mkIf vaultPkiCfg.enable [ "d ${vaultPkiCfg.certDirectory} 0750 caddy caddy - -" ];

        systemd.services = {
          caddy = mkIf vaultPkiCfg.useForRoutes {
            after = [ "caddy-vault-pki-certificate.service" ];
            wants = [ "caddy-vault-pki-certificate.service" ];
          };

          caddy-vault-pki-certificate = mkIf vaultPkiCfg.enable {
            description = "Renew Caddy certificate from Vault PKI";
            after = [ "network-online.target" ];
            before = lib.optionals vaultPkiCfg.useForRoutes [ "caddy.service" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "oneshot";
            script = ''
              exec ${lib.getExe vaultPkiRenewScript}
            '';
          };
        };

        systemd.timers.caddy-vault-pki-certificate = mkIf vaultPkiCfg.enable {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "15min";
            OnUnitActiveSec = "12h";
            Persistent = true;
            RandomizedDelaySec = "30min";
            Unit = "caddy-vault-pki-certificate.service";
          };
        };
      };
    };
}
