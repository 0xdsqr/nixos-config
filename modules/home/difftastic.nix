{
  flake.homeModules.difftastic =
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

      cfg = config.dsqr.home.difftastic;

      difftDark = pkgs.callPackage (
        {
          difftastic,
          lib,
          writeShellScriptBin,
        }:
        writeShellScriptBin "difft-dark" /* bash */ ''
          exec ${lib.meta.getExe difftastic} --background ${osConfig.theme.difftastic.background} "$@"
        ''
      ) { };
    in
    {
      options.dsqr.home.difftastic = {
        enable = mkEnableOption "difftastic git diff integration" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.difftastic;
          description = "difftastic package to install.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = [
          cfg.package
          difftDark
        ];

        programs.git.settings = {
          diff.external = getExe difftDark;
          diff.tool = "difftastic";
          difftool.difftastic.cmd = ''${getExe difftDark} "$LOCAL" "$REMOTE"'';
        };
      };
    };
}
