{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ssh server configuration - enables secure remote access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = true;
}
