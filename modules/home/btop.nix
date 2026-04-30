{
  flake.homeModules.btop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.btop;
    in
    {
      options.dsqr.home.btop = {
        enable = mkEnableOption "btop system monitor" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.btop;
          description = "btop package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        xdg.configFile."btop/themes/dsqr.theme" = {
          text = /* ini */ ''
            theme[main_bg]="#1f1b18"
            theme[main_fg]="#e7d9c8"
            theme[title]="#f0c674"
            theme[hi_fg]="#f0c674"
            theme[selected_bg]="#4a3a2a"
            theme[selected_fg]="#f7efe5"
            theme[inactive_fg]="#6f6155"
            theme[graph_text]="#d7b16d"
            theme[meter_bg]="#2a241f"
            theme[proc_misc]="#b48ead"
            theme[cpu_box]="#7ea1c5"
            theme[mem_box]="#9aad6d"
            theme[net_box]="#7eb5a6"
            theme[proc_box]="#c97b63"
            theme[div_line]="#5a4633"
            theme[temp_start]="#9aad6d"
            theme[temp_mid]="#d7b16d"
            theme[temp_end]="#c97b63"
            theme[cpu_start]="#7eb5a6"
            theme[cpu_mid]="#d7b16d"
            theme[cpu_end]="#c97b63"
            theme[free_start]="#7eb5a6"
            theme[free_mid]="#9aad6d"
            theme[free_end]="#d7b16d"
            theme[cached_start]="#7ea1c5"
            theme[cached_mid]="#b48ead"
            theme[cached_end]="#c97b63"
            theme[available_start]="#7eb5a6"
            theme[available_mid]="#9aad6d"
            theme[available_end]="#d7b16d"
            theme[used_start]="#d7b16d"
            theme[used_mid]="#c97b63"
            theme[used_end]="#c97b63"
            theme[download_start]="#7ea1c5"
            theme[download_mid]="#7eb5a6"
            theme[download_end]="#9aad6d"
            theme[upload_start]="#b48ead"
            theme[upload_mid]="#d7b16d"
            theme[upload_end]="#c97b63"
          '';
        };

        xdg.configFile."btop/btop.conf" = {
          text = /* ini */ ''
            color_theme = "dsqr"
            rounded_corners = False
            vim_keys = True
          '';
        };
      };
    };
}
