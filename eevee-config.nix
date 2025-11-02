lib: {
  eeveeOptions = {
    full_name = lib.mkOption {
      type = lib.types.str;
      description = "Main user's full name";
    };
    email_address = lib.mkOption {
      type = lib.types.str;
      description = "Main user's email address";
    };
    theme = lib.mkOption {
      type = lib.types.either (lib.types.enum [
        "tokyo-night"
      ]) lib.types.str;
      default = "tokyo-night";
      description = "Theme to use for dsqr-nix configuration";
    };
  };
}
