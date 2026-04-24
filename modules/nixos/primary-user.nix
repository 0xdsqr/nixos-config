{
  flake.nixosModules."dsqr-user" =
    {
      config,
      hostMeta,
      keys,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOption types;
      defaultPasswordAgeFile =
        let
          agePath = hostMeta.path + "/host.password.age";
        in
        if builtins.pathExists agePath then agePath else null;
      cfg = config.dsqr.nixos.user;
    in
    {
      options.dsqr.nixos.user = {
        passwordAgeFile = mkOption {
          type = types.nullOr types.path;
          default = defaultPasswordAgeFile;
          description = "Encrypted age file that stores the shared password hash for dsqr and root.";
        };
      };

      config = mkIf (cfg.passwordAgeFile != null) {
        age.secrets.hostPassword.file = cfg.passwordAgeFile;

        users.users.dsqr = {
          isNormalUser = true;
          home = "/home/dsqr";
          description = "its me dave";
          hashedPasswordFile = config.age.secrets.hostPassword.path;
          extraGroups = [
            "wheel"
            "networkmanager"
            "docker"
            "lxd"
          ];
          openssh.authorizedKeys.keys = keys.admins;
        };

        users.users.root.hashedPasswordFile = config.age.secrets.hostPassword.path;
      };
    };
}
