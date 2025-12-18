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
      description = "Theme to use for eevee configuration";
    };
    nixos.exclude_packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to exclude from NixOS systemPackages";
    };
    darwin.exclude_casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew casks to exclude from Darwin setup";
    };
  };
}
