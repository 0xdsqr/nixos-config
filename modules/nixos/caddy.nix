{
  flake.nixosModules.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.strings) concatStringsSep optionalString;
      inherit (lib.types)
        attrsOf
        bool
        lines
        listOf
        str
        submodule
        ;

      cfg = config.dsqr.nixos.caddy;
      internalSourceRanges = concatStringsSep " " cfg.allowedSourceRanges;

      mkVirtualHost = _hostName: route: {
        extraConfig = ''
          ${optionalString route.tlsInternal "tls internal"}
          encode zstd gzip

          @internal remote_ip ${internalSourceRanges}
          handle @internal {
            reverse_proxy ${route.upstream}
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
            };
          });
          default = { };
          description = "Internal hostnames and their reverse proxy upstreams.";
        };
      };

      config = mkIf cfg.enable {
        services.caddy = {
          enable = true;
          inherit (cfg) package;
          virtualHosts = mapAttrs mkVirtualHost cfg.routes;
        };

        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          80
          443
        ];
      };
    };
}
