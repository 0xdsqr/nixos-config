{
  flake.nixosModules.system =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      users.mutableUsers = false;

      security.sudo.wheelNeedsPassword = false;

      boot.tmp.cleanOnBoot = true;

      time.timeZone = mkDefault "America/Chicago";
      i18n.defaultLocale = mkDefault "en_US.UTF-8";

      networking.firewall.enable = true;
      networking.useDHCP = mkDefault true;
    };
}
