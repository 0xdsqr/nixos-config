{ keys, ... }:
{
  users.groups.build = { };

  users.users.build = {
    isNormalUser = true;
    createHome = true;
    home = "/var/lib/build";
    description = "distributed nix builder";
    group = "build";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = keys.admins;
  };

  systemd.tmpfiles.rules = [ "d /var/lib/build 0750 build build -" ];
}
