{ lib, ... }: {
  dsqr.nixos.postgresql = {
    roles.knox_replication.replication = true;

    hostAuthenticationRules = [
      {
        database = "replication";
        user = "knox_replication";
        address = "10.10.30.109/32";
      }
    ];
  };

  services.postgresql.settings.max_slot_wal_keep_size = lib.mkForce "16 GB";
}
