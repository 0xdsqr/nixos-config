{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  dsqr.home.herdr = {
    enable = mkDefault true;
    layouts.dev.enable = mkDefault true;
    integrations = {
      codex.enable = mkDefault true;
      claude.enable = mkDefault true;
      pi.enable = mkDefault true;
      opencode.enable = mkDefault true;
    };
  };
}
