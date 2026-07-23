_:
let
  certificate = {
    directory = "/var/lib/postgresql/tls";
    certificateFile = "/var/lib/postgresql/tls/server.crt";
    privateKeyFile = "/var/lib/postgresql/tls/server.key";
  };
in
{
  dsqr.nixos.vaultCertificates.postgresql = {
    roleId = "04b1bf02-17ae-a477-094c-57a264932495";
    secretIdAgeFile = ./listener-pki.secret-id.age;
    issuePath = "pki_int/issue/postgres-knox-listener";
    commonName = "postgres.service.home.arpa";
    inherit (certificate) directory certificateFile privateKeyFile;
    owner = "postgres";
    group = "postgres";
    reloadUnit = "postgresql.service";
  };

  dsqr.nixos.postgresql.tls = {
    enable = true;
    inherit (certificate) certificateFile privateKeyFile;
  };
}
