_: {
  dsqr.nixos.redis = {
    enable = true;
    passwordAgeFile = ./redis.password.age;
  };
}
