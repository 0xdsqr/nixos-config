{
  config,
  keys,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dsqr.nixos.builder;
in
{
  config = lib.mkIf cfg.enable {
    users.groups.build = { };

    users.users.${cfg.sshUser} = {
      isSystemUser = true;
      group = "build";
      home = "/var/lib/build";
      createHome = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = keys.admins;
    };

    nix.settings.trusted-users = lib.mkAfter [ cfg.sshUser ];
  };
}
