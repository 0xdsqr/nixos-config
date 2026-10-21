_: {
  # Password is provisioned directly into Vault and PostgreSQL, never the store.
  dsqr.nixos.postgresql.roles.dotdev_runtime = { };

  dsqr.nixos.postgresql.databases = {
    postgres = {
      owner = "postgres";
      extensions = [ "pg_stat_statements" ];
    };

    dsqr = { };
    "dsqr-dotdev" = { };
    fidara = { };
    grafana = { };
    tastingswithtay = { };
    temporal = { };

    temporal_visibility = {
      owner = "temporal";
      extensions = [ "btree_gin" ];
    };
  };
}
