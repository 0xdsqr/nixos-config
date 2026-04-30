{
  flake.nixosModules.fonts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package str;

      cfg = config.dsqr.nixos.fonts;
    in
    {
      options.dsqr.nixos.fonts = {
        enable = mkEnableOption "Enable the shared NixOS font baseline";

        console = {
          font = mkOption {
            type = str;
            default = "Lat2-Terminus16";
            description = "Linux console font name.";
          };

          package = mkOption {
            type = package;
            default = pkgs.terminus_font;
            defaultText = "pkgs.terminus_font";
            description = "Package providing the Linux console font.";
          };
        };
      };

      config = mkIf cfg.enable {
        console = {
          earlySetup = true;
          inherit (cfg.console) font;
          packages = [ cfg.console.package ];
        };
      };
    };
}
