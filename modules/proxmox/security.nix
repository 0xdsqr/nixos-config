{
  config,
  lib,
  pkgs,
  ...
}:
{
  # allow members of the wheel group to use sudo without entering a password
  security.sudo.wheelNeedsPassword = false;
}
