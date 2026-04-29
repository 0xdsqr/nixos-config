{
  flake.homeModules.bat =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.bat;

      batPager = pkgs.callPackage (
        {
          bat,
          lib,
          writeShellScriptBin,
        }:
        writeShellScriptBin "bat-pager" /* bash */ ''
          exec ${lib.meta.getExe bat} --plain "$@"
        ''
      ) { };
    in
    {
      options.dsqr.home.bat = {
        enable = mkEnableOption "bat defaults for the shell and pager" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.bat;
          description = "bat package to install and configure.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = [
          cfg.package
          pkgs.less
          batPager
        ];

        home.sessionVariables.MANPAGER = getExe batPager;
        home.sessionVariables.PAGER = getExe batPager;

        programs.nushell.shellAliases.cat = "bat";
        programs.nushell.shellAliases.less = "bat --plain";

        xdg.configFile."bat/config" = {
          text = /* ini */ ''
            --style=numbers,changes,header
            --theme=${osConfig.theme.bat.themeName}
            --pager="${getExe pkgs.less} --quit-if-one-screen --quit-on-intr --RAW-CONTROL-CHARS"
          '';
        };
      };
    };
}
