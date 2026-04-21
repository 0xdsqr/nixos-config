{ config, nix-openclaw, ... }:
{
  age.secrets.openclawGatewayAuthToken = {
    file = ./gateway.auth-token.age;
    path = "/run/agenix/openclaw-gateway-auth-token";
    owner = "dsqr";
    mode = "0400";
  };

  home-manager.users.dsqr = {
    imports = [ nix-openclaw.homeManagerModules.openclaw ];

    programs.openclaw = {
      enable = true;

      config = {
        secrets = {
          providers = {
            gatewayauth = {
              source = "file";
              inherit (config.age.secrets.openclawGatewayAuthToken) path;
              mode = "singleValue";
            };
          };
          defaults.file = "gatewayauth";
        };

        gateway = {
          mode = "local";
          auth = {
            mode = "token";
            token = {
              source = "file";
              provider = "gatewayauth";
              id = "value";
            };
          };
        };
      };
    };
  };
}
