{
  flake.darwinModules."dsqr-user" =
    _: {
      users.users.dsqr.home = "/Users/dsqr";
      system.primaryUser = "dsqr";
    };
}
