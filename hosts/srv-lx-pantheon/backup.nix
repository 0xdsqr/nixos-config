{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) genAttrs;
  gatewayServices = [
    "hermes-agent.service"
    "hermes-agent-vanilla.service"
  ];
  gateways = lib.concatStringsSep " " gatewayServices;
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
