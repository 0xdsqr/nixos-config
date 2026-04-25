{
  flake.homeModules.difftastic =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      difftDark = pkgs.writeShellScriptBin "difft-dark" ''
        exec ${getExe pkgs.difftastic} --background dark "$@"
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
