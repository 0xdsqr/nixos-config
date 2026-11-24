_: {
  # Password is provisioned directly into Vault and PostgreSQL, never the store.
  dsqr.nixos.postgresql.roles = {
    dotdev_runtime = { };

    twt_runtime.login = false;

    twt_web_indigo_runtime.memberships = [ "twt_runtime" ];
    twt_admin_indigo_runtime.memberships = [ "twt_runtime" ];
  };

  dsqr.nixos.postgresql.databases = {
    postgres = {
      owner = "postgres";
      extensions = [ "pg_stat_statements" ];
    };

    dsqr = { };
    "dsqr-dotdev" = { };
    fidara = { };
    grafana = { };
    tastingswithtay.runtimeAccessRoles = [ "twt_runtime" ];
    temporal = { };

    temporal_visibility = {
      owner = "temporal";
      extensions = [ "btree_gin" ];
    };
  };
}
