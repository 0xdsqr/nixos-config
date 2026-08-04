_: {
  dsqr.nixos.backup.server = {
    enable = true;
    rootDirectory = "/var/lib/backup";

    pgBackRest = {
      enable = true;
      authorizedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnQTtJ33sAHJOxWcKulRWEtHr/RbYQzVsjMm4X4jxm9 pgbackrest@srv-lx-knox";
      repositoryEnvironmentAgeFile = ./pgbackrest-repository.env.age;
    };
  };
}
