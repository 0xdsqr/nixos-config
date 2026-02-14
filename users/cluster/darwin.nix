{ currentSystemUser, pkgs, ... }:
{
  users.users.${currentSystemUser} = {
    home = "/Users/${currentSystemUser}";
    shell = pkgs.zsh;
  };

  system.primaryUser = currentSystemUser;
}
