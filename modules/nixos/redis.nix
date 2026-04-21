{ config, lib, ... }:
let
  cfg = config.dsqr.nixos.redis;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.passwordAgeFile != null;
        message = "dsqr.nixos.redis.passwordAgeFile must be set when dsqr.nixos.redis.enable = true;";
      }
    ];

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
}
