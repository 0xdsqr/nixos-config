{
  flake.nixosModules."dsqr-user" =
    { config, lib, ... }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        bool
        listOf
        nullOr
        path
        str
        ;

      cfg = config.dsqr.nixos.user;
      hasPasswordAgeFile = cfg.passwordAgeFile != null && builtins.pathExists cfg.passwordAgeFile;
      userName = if cfg.name == null then "primary-user-unset" else cfg.name;
    in
    {
      options.dsqr.nixos.user = {
        enable = mkEnableOption "Enable the shared primary NixOS user";

        name = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary NixOS user name.";
        };

        home = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary NixOS user home directory.";
        };

        description = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary NixOS user description.";
        };

        extraGroups = mkOption {
          type = listOf str;
          default = [ ];
          description = "Extra groups assigned to the primary NixOS user.";
        };

        authorizedKeys = mkOption {
          type = listOf str;
          default = [ ];
          description = "SSH authorized keys for the primary NixOS user.";
        };

        passwordAgeFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Encrypted age file that stores the shared password hash for the primary user.";
        };

        setRootPassword = mkOption {
          type = bool;
          default = true;
          description = "Whether to reuse passwordAgeFile for the root password.";
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.name != null;
            message = "dsqr.nixos.user.name must be set when dsqr.nixos.user.enable is true.";
          }
        ];

        age.secrets.hostPassword = mkIf hasPasswordAgeFile { file = cfg.passwordAgeFile; };

        users.users.${userName} = {
          isNormalUser = true;
          hashedPasswordFile = mkIf hasPasswordAgeFile config.age.secrets.hostPassword.path;
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        }
        // optionalAttrs (cfg.home != null) { inherit (cfg) home; }
        // optionalAttrs (cfg.description != null) { inherit (cfg) description; }
        // optionalAttrs (cfg.extraGroups != [ ]) { inherit (cfg) extraGroups; };

        users.users.root.hashedPasswordFile = mkIf (
          cfg.setRootPassword && hasPasswordAgeFile
        ) config.age.secrets.hostPassword.path;
      };
    };
}
