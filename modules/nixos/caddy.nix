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
        enum
        lines
        listOf
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.nixos.caddy;
      certificateCfg = cfg.certificate;
      internalSourceRanges = concatStringsSep " " cfg.allowedSourceRanges;
      configuredStaticCertificate = certificateCfg.certFile != null && certificateCfg.keyFile != null;
      routeTlsDirective =
        if configuredStaticCertificate then "tls ${certificateCfg.certFile} ${certificateCfg.keyFile}" else "tls internal";

      mkReverseProxy =
        route:
        let
          hasHostHeader = route.hostHeader != null;
          hasFailover = route.failover.upstreams != [ ];
          hasTransportConfig = route.tlsInsecureSkipVerify || route.tlsServerName != null;
          upstreams = concatStringsSep " " ([ route.upstream ] ++ route.failover.upstreams);
        in
        if !hasHostHeader && !hasFailover && !hasTransportConfig then
          "reverse_proxy ${upstreams}"
        else
          ''
            reverse_proxy ${upstreams} {
              ${optionalString hasHostHeader "header_up Host ${route.hostHeader}"}
              ${optionalString hasFailover ''
                lb_policy first
                health_uri ${route.failover.healthUri}
                lb_try_duration ${route.failover.tryDuration}
              ''}
              ${optionalString hasTransportConfig ''
                transport http {
                  ${optionalString (route.tlsServerName != null) "tls_server_name ${route.tlsServerName}"}
                  ${optionalString route.tlsInsecureSkipVerify "tls_insecure_skip_verify"}
                }
              ''}
            }
          '';

      mkVirtualHost =
        _hostName: route:
        let
          basicAuthUsers = concatStringsSep "\n" (
            mapAttrsToList (user: passwordHash: "${user} ${passwordHash}") route.basicAuth.users
          );
        in
        {
          extraConfig = ''
            ${optionalString route.tlsInternal routeTlsDirective}
            encode zstd gzip

            ${optionalString (route.basicAuth.users != { }) ''
              basic_auth ${route.basicAuth.algorithm} {
                ${basicAuthUsers}
              }
            ''}

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
                description = "Primary HTTP upstream target for this virtual host.";
                example = "http://10.10.30.102:8000";
              };

              failover = {
                upstreams = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Ordered fallback upstreams used when the primary upstream is unhealthy.";
                  example = [ "http://10.10.30.103:8000" ];
                };

                healthUri = mkOption {
                  type = nullOr str;
                  default = null;
                  description = "HTTP path used to health-check the primary and fallback upstreams.";
                  example = "/health";
                };

                tryDuration = mkOption {
                  type = str;
                  default = "5s";
                  description = "Maximum time Caddy retries available upstreams for a request.";
                };
              };

              basicAuth = {
                algorithm = mkOption {
                  type = enum [
                    "argon2id"
                    "bcrypt"
                  ];
                  default = "argon2id";
                  description = "Password hashing algorithm used for HTTP Basic Authentication.";
                };

                users = mkOption {
                  type = attrsOf str;
                  default = { };
                  description = "Usernames mapped to password hashes for HTTP Basic Authentication.";
                  example.dsqr = "$argon2id$v=19$m=47104,t=1,p=1$...";
                };
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
                example = "argocd.hub-a.home.arpa";
              };

              tlsServerName = mkOption {
                type = nullOr str;
                default = null;
                description = "Optional SNI server name used for HTTPS upstreams.";
                example = "argocd.hub-a.home.arpa";
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

      };

      config = mkIf cfg.enable {
        assertions =
          mapAttrsToList (hostName: route: {
            assertion = route.pathRegexp != null || route.paths != [ ];
            message = "dsqr.nixos.caddy.httpRoutes.${hostName} must set paths or pathRegexp.";
          }) cfg.httpRoutes
          ++ mapAttrsToList (hostName: route: {
            assertion = route.failover.upstreams == [ ] || route.failover.healthUri != null;
            message = "dsqr.nixos.caddy.routes.${hostName}.failover.healthUri is required when fallback upstreams are configured.";
          }) cfg.routes
          ++ [
            {
              assertion = (certificateCfg.certFile == null) == (certificateCfg.keyFile == null);
              message = "dsqr.nixos.caddy.certificate.certFile and keyFile must be set together.";
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
      };
    };
}
