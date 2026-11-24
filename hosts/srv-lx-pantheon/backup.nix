{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) genAttrs;
  # The host gateway serves every profile (hoo and vanilla).
  gateways = "hermes-agent.service";
in
{
  services.restic.backups = genAttrs config.services.restic.hosts (_: {
    paths = [ config.services.hermes-agent.stateDir ];

    backupPrepareCommand = ''
      ${pkgs.systemd}/bin/systemctl stop ${gateways}
    '';

    backupCleanupCommand = ''
      ${pkgs.systemd}/bin/systemctl start ${gateways}
    '';
  });
}
