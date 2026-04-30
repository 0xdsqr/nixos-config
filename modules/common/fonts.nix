{
  flake.commonModules.fonts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.fonts;
    in
    {
      options.dsqr.fonts.enable = mkEnableOption "shared system fonts" // {
        default = true;
      };

      config = mkIf cfg.enable {
        fonts.packages = [
          pkgs.lexend
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-lgc-plus
          pkgs.noto-fonts-color-emoji
        ];
      };
    };
}
