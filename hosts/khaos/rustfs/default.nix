{ config, inputs, ... }:
{
  imports = [ inputs.rustfs.nixosModules.rustfs ];

  age.secrets.rustfsAccessKey = {
    file = ./access-key.age;
    mode = "0400";
  };

  age.secrets.rustfsSecretKey = {
    file = ./secret-key.age;
    mode = "0400";
  };

  networking.firewall.allowedTCPPorts = [
    9000
    9001
  ];

  services.rustfs = {
    enable = true;
    package = inputs.rustfs.packages.${config.nixpkgs.hostPlatform.system}.default;
    accessKeyFile = config.age.secrets.rustfsAccessKey.path;
    secretKeyFile = config.age.secrets.rustfsSecretKey.path;
    volumes = [ "/var/lib/rustfs/data" ];
    address = "0.0.0.0:9000";
    consoleEnable = true;
    consoleAddress = "0.0.0.0:9001";
    logLevel = "warn";
    logDirectory = "/var/log/rustfs";
  };

  warnings = [
    ''
      RustFS on khaos is currently wired for a single local data path at /var/lib/rustfs/data.
      Upstream recommends XFS on dedicated JBOD disks for serious use; switch RUSTFS_VOLUMES and
      host mounts before treating this as a production deployment.
    ''
  ];
}
