{
  flake.darwinModules."dsqr-user" =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) str;

      cfg = config.dsqr.darwin.personal.user;
    in
    {
      options.dsqr.darwin.personal.user = {
        enable = mkEnableOption "personal Darwin user" // {
          default = true;
        };

        name = mkOption {
          type = str;
          default = "dsqr";
          description = "Primary Darwin user name.";
        };

        home = mkOption {
          type = str;
          default = "/Users/${cfg.name}";
          description = "Primary Darwin user home directory.";
        };
      };

      config = mkIf cfg.enable {
        users.users.${cfg.name}.home = cfg.home;
        system.primaryUser = cfg.name;
      };
    };
}
