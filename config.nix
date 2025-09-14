lib: {
  dsqrDevboxOptions = {
    theme = lib.mkOption {
      type = lib.types.str;
      default = "tokyo-night";
      description = "Theme for dsqr-devbox";
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
