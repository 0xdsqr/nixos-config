_:
let
  keys = import ../../profiles/dsqr/keys.nix;
in
{
  dsqr.nixos.backup.postgresql = {
    enable = true;
    repositoryHost = "10.10.30.111";
    repositoryHostPublicKey = keys.hosts.srv-lx-backup;
    repositorySshPrivateKeyAgeFile = ./pgbackrest-repository.key.age;
    repositoryEnvironmentAgeFile = ../srv-lx-backup/pgbackrest-repository.env.age;
  };
}
