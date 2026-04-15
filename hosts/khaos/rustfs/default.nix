{
  config,
  inputs,
  pkgs,
  ...
}:
let
  rustfsPackage = inputs.rustfs.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  age.secrets.rustfsEnv = {
    file = ./env.age;
    mode = "0400";
    owner = "rustfs";
    group = "rustfs";
  };

  users.groups.rustfs = {
    gid = 10001;
  };

  users.users.rustfs = {
    isSystemUser = true;
    uid = 10001;
    group = "rustfs";
    home = "/var/lib/rustfs";
    createHome = true;
  };

  networking.firewall.allowedTCPPorts = [
    9000
    9001
  ];

  environment.systemPackages = [ rustfsPackage ];

  systemd.tmpfiles.rules = [
    "d /var/lib/rustfs 0750 rustfs rustfs -"
    "d /var/lib/rustfs/data 0750 rustfs rustfs -"
    "d /var/log/rustfs 0750 rustfs rustfs -"
  ];

  systemd.services.rustfs = {
    description = "RustFS Object Storage Server";
    documentation = [ "https://docs.rustfs.com/" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      RUSTFS_ADDRESS = "0.0.0.0:9000";
      RUSTFS_CONSOLE_ADDRESS = "0.0.0.0:9001";
      RUSTFS_CONSOLE_ENABLE = "true";
      RUSTFS_VOLUMES = "/var/lib/rustfs/data";
      RUST_LOG = "warn";
      RUSTFS_OBS_LOG_DIRECTORY = "/var/log/rustfs";
    };

    serviceConfig = {
      Type = "notify";
      NotifyAccess = "main";

      User = "rustfs";
      Group = "rustfs";
      WorkingDirectory = "/var/lib/rustfs";
      EnvironmentFile = [ config.age.secrets.rustfsEnv.path ];

      ExecStart = "${rustfsPackage}/bin/rustfs $RUSTFS_VOLUMES";

      Restart = "always";
      RestartSec = "10s";

      LimitNOFILE = 1048576;
      LimitNPROC = 32768;
      TasksMax = "infinity";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;

      TimeoutStartSec = "30s";
      TimeoutStopSec = "30s";
    };
  };

  warnings = [
    ''
      RustFS on khaos is currently wired for a single local data path at /var/lib/rustfs/data.
      Upstream recommends XFS on dedicated JBOD disks for serious use; switch RUSTFS_VOLUMES and
      host mounts before treating this as a production deployment.
    ''
  ];
}
