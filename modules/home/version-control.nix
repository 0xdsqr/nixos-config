{
  flake.homeModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.home.versionControl;
    in
    {
      options.dsqr.home.versionControl = {
        enable = mkEnableOption "version control tooling" // {
          default = true;
        };

        lazygit.enable = mkEnableOption "lazygit" // {
          default = true;
        };

        gh.enable = mkEnableOption "GitHub CLI integration" // {
          default = true;
        };

        gpg.enable = mkEnableOption "GPG tooling" // {
          default = true;
        };
      };

      config = mkIf cfg.enable {
        home.packages = mkIf cfg.lazygit.enable (singleton pkgs.lazygit);

        programs.git.enable = true;
        programs.git.signing = {
          key = "6908FE142198DB65";
          signByDefault = true;
          format = "openpgp";
        };
        programs.git.settings = {
          alias = {
            cleanup = "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
            prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
            root = "rev-parse --show-toplevel";
          };
          branch.autosetuprebase = "always";
          color.ui = true;
          core.editor = "nvim";
          core.askPass = "";
          credential.helper = "store";
          github.user = "0xdsqr";
          push.default = "tracking";
          init.defaultBranch = "main";
          user = {
            name = "0xdsqr";
            email = "me@dsqr.dev";
          };
        };

        programs.gh.enable = mkIf cfg.gh.enable true;
        programs.gh.gitCredentialHelper.enable = mkIf cfg.gh.enable true;

        programs.gpg.enable = mkIf cfg.gpg.enable true;

        services.gpg-agent = mkIf (cfg.gpg.enable && pkgs.stdenv.isLinux) {
          enable = true;
          pinentry.package = pkgs.pinentry-curses;
          enableSshSupport = true;
        };
      };
    };
}
