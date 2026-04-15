{ lib, ... }:
{
  users.mutableUsers = false;

  boot.tmp.cleanOnBoot = true;

  time.timeZone = lib.mkDefault "America/Chicago";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  networking.firewall.enable = true;
  networking.useDHCP = lib.mkDefault true;
}
