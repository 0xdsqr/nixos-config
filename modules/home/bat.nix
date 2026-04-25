{
  flake.homeModules.bat =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;

      batPager = pkgs.writeShellScriptBin "bat-pager" ''
        exec ${getExe pkgs.bat} --plain "$@"
      '';
    in
    {
      home.packages = [
        pkgs.bat
        pkgs.less
        batPager
      ];

      home.sessionVariables = {
        MANPAGER = getExe batPager;
        PAGER = getExe batPager;
      };

      programs.nushell.shellAliases = {
        cat = "bat";
        less = "bat --plain";
      };

      xdg.configFile."bat/config".text = ''
        --style=numbers,changes,header
        --theme=TwoDark
        --pager="${getExe pkgs.less} --quit-if-one-screen --quit-on-intr --RAW-CONTROL-CHARS"
      '';
    };
}
