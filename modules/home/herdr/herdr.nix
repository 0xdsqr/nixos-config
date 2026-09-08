{
  flake.homeModules.herdr =
    { config, lib, ... }:
    let
      inherit (lib.modules) mkAliasOptionModule mkDefault mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.herdr;
    in
    {
      imports = [ (mkAliasOptionModule [ "dsqr" "home" "herdr" "settings" ] [ "programs" "herdr" "settings" ]) ];

      options.dsqr.home.herdr.enable = mkEnableOption "Herdr";

      config = mkIf cfg.enable {
        programs.herdr = {
          enable = true;
          settings = {
            onboarding = mkDefault false;
            terminal.default_shell = mkDefault "";
            worktrees.directory = mkDefault "~/.herdr/worktrees";
            keys = {
              prefix = mkDefault "ctrl+space";
              detach = mkDefault [
                "prefix+d"
                "prefix+q"
              ];
              settings = mkDefault "prefix+shift+s";
              workspace_picker = mkDefault [
                "prefix+s"
                "prefix+w"
              ];
            };
            ui.sidebar_start_collapsed = mkDefault false;
          };
        };
      };
    };
}
