{
  flake.homeModules.difftastic =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      difftDark = pkgs.writeShellScriptBin "difft-dark" ''
        exec ${getExe pkgs.difftastic} --background ${osConfig.theme.difftastic.background} "$@"
      '';
    in
    {
      home.packages = [
        pkgs.difftastic
        difftDark
      ];

      programs.git.settings = {
        diff.external = getExe difftDark;
        diff.tool = "difftastic";
        difftool.difftastic.cmd = ''${getExe difftDark} "$LOCAL" "$REMOTE"'';
      };
    };
}
