_: {
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
