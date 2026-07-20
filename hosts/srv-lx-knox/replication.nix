_: {
  age.secrets.postgresqlReplicationPgpass = {
    file = ./postgresql-replication.pgpass.age;
    owner = "postgres";
    group = "postgres";
    mode = "0400";
  };
}
