{
  flake.nixosModules.redis =
    { config, lib, ... }:
    let
      inherit (lib) mkIf mkOption types;
      cfg = config.dsqr.nixos.redis;
    in
    {
      options.dsqr.nixos.redis = {
        passwordAgeFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Encrypted age file that stores the Redis password.";
        };
      };

      config = mkIf (cfg.passwordAgeFile != null) {
        age.secrets.redisPassword = {
          file = cfg.passwordAgeFile;
          owner = "redis-main";
          group = "redis-main";
          mode = "0400";
        };

        networking.firewall.allowedTCPPorts = [ 6379 ];

        services.redis.servers.main = {
          enable = true;
          bind = "0.0.0.0";
          port = 6379;
          requirePassFile = config.age.secrets.redisPassword.path;
          settings = {
            protected-mode = "no";
          };
        };
      };
    };
}
