{ keys, lib, ... }:
{
  users.mutableUsers = false;

  users.users.dsqr = {
    isNormalUser = true;
    home = "/home/dsqr";
    description = "its me dave";
    extraGroups = lib.mkDefault [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = keys.admins;
  };

  boot.tmp.cleanOnBoot = true;

  time.timeZone = lib.mkDefault "America/Chicago";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  networking.firewall.enable = true;
  networking.useDHCP = lib.mkDefault true;
}
