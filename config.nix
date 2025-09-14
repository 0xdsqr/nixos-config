lib: {
  dsqrDevboxOptions = {
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
        "kanagawa"
        "everforest"
        "catppuccin"
        "nord"
        "gruvbox"
        "gruvbox-light"
        "generated_light"
        "generated_dark"
      ]) lib.types.str;
      default = "tokyo-night";
      description = "Theme to use for dsqr-nix configuration";
    };

    theme_overrides = lib.mkOption {
      type = lib.types.submodule {
        options = {
          wallpaper_path = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to the wallpaper image to extract colors from";
          };
        };
      };
      default = { };
      description = "Theme overrides including wallpaper path for generated themes";
    };
    scale = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Display scale factor (1 for 1x displays, 2 for 2x displays)";
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
