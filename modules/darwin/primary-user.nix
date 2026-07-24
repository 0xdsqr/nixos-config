{
  flake.darwinModules."dsqr-user" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) listOf nullOr str;

      cfg = config.dsqr.darwin.personal.user;
      userName = if cfg.name == null then "primary-user-unset" else cfg.name;
    in
    {
      options.dsqr.darwin.personal.user = {
        enable = mkEnableOption "primary Darwin user";

        name = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary Darwin user name.";
        };

        home = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary Darwin user home directory.";
        };

        authorizedKeys = mkOption {
          type = listOf str;
          default = [ ];
          description = "SSH authorized keys for the primary Darwin user.";
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.name != null;
            message = "dsqr.darwin.personal.user.name must be set when dsqr.darwin.personal.user.enable is true.";
          }
          {
            assertion = cfg.home != null;
            message = "dsqr.darwin.personal.user.home must be set when dsqr.darwin.personal.user.enable is true.";
          }
        ];

        users.users.${userName} = {
          home = mkIf (cfg.home != null) cfg.home;
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        };
        system.primaryUser = userName;
      };
    };
}
