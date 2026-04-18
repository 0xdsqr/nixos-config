{
  config,
  keys,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    genAttrs
    mkIf
    mkOption
    types
    ;
  cfg = config.services.restic;
in
{
  options.services.restic.hosts = mkOption {
    type = types.listOf types.str;
    default =
      if config.networking.hostName == "beacon" then
        [ "khaos" ]
      else if config.networking.hostName == "khaos" then
        [ "beacon" ]
      else
        [ ];
    description = "Hosts that should receive this machine's restic backups.";
  };

  options.services.restic.passwordAgeFile = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Encrypted age file that stores the shared restic repository password.";
  };

  config = mkIf (cfg.hosts != [ ] && cfg.passwordAgeFile != null) {
    age.secrets.resticPassword.file = cfg.passwordAgeFile;

    environment.systemPackages = [ pkgs.restic ];

    users.users.backup = {
      description = "Backup";
      isNormalUser = true;
      openssh.authorizedKeys.keys = keys.all;
    };

    services.restic.backups = genAttrs cfg.hosts (host: {
      repository = "sftp:backup@${host}:${config.networking.hostName}-backup";
      passwordFile = config.age.secrets.resticPassword.path;
      initialize = true;
      extraOptions = [
        "sftp.command='ssh -i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=accept-new backup@${host} -s sftp'"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    });
  };
}
