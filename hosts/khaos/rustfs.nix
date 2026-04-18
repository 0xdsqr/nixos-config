_: {
  dsqr.nixos.rustfs = {
    enable = true;
    accessKeyAgeFile = ./rustfs.access-key.age;
    secretKeyAgeFile = ./rustfs.secret-key.age;
  };
}
