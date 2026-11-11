{ inputs, ... }: {
  flake.nixosModules.rex =
    { config, lib, ... }:
    let
      inherit (lib.attrsets) genAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        bool
        listOf
        port
        str
        ;

      cfg = config.dsqr.nixos.rex;
    in
    {
      imports = [ inputs.rex.nixosModules.default ];

      options.dsqr.nixos.rex = {
        enable = mkEnableOption "Rex login server";

        account = mkOption {
          type = str;
          default = config.dsqr.nixos.user.name;
          defaultText = lib.literalExpression "config.dsqr.nixos.user.name";
          description = "Local account made available through the Rex login server.";
        };

        principals = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "tailscale:alice@example.com" ];
          description = "Tailscale principals allowed to use the configured local account.";
        };

        socketActivation = mkOption {
          type = bool;
          default = true;
          description = "Start the Rex login server when its first client connects.";
        };

        tailscaleServe = {
          enable = mkEnableOption "Rex access through Tailscale Serve" // {
            default = true;
          };

          httpsPort = mkOption {
            type = port;
            default = 7297;
            description = "Tailnet HTTPS port used by Rex through Tailscale Serve.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.principals != [ ];
            message = "dsqr.nixos.rex.principals must contain at least one Tailscale principal.";
          }
          {
            assertion = !cfg.tailscaleServe.enable || config.services.tailscale.enable;
            message = "dsqr.nixos.rex.tailscaleServe.enable requires services.tailscale.enable = true.";
          }
        ];

        services.rex.loginServer = {
          enable = true;
          inherit (cfg) socketActivation;

          accounts.${cfg.account}.principals = cfg.principals;
          defaults = genAttrs cfg.principals (_: cfg.account);

          tailscaleServe = { inherit (cfg.tailscaleServe) enable httpsPort; };
        };
      };
    };
}
