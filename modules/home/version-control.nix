{
  flake.homeModules.git =
    { pkgs, lib, ... }:
    let
      inherit (lib) mkIf;
    in
    {
      programs.git = {
        enable = true;
        signing = {
          key = "6908FE142198DB65";
          signByDefault = true;
          format = "openpgp";
        };
        settings = {
          alias = {
            cleanup = "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
            prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
            root = "rev-parse --show-toplevel";
          };
          branch.autosetuprebase = "always";
          color.ui = true;
          core.editor = "nvim";
          core.askPass = ""; # Use terminal for askpass
          credential.helper = "store"; # want to make this more secure
          github.user = "0xdsqr";
          push.default = "tracking";
          init.defaultBranch = "main";
          user = {
            name = "0xdsqr";
            email = "me@dsqr.dev";
          };
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper = {
          enable = true;
        };
      };

      programs.gpg = {
        enable = true;
      };

      # gpg-agent works on both Linux and Darwin
      services.gpg-agent = mkIf pkgs.stdenv.isLinux {
        enable = true;
        pinentry.package = pkgs.pinentry-curses;
        enableSshSupport = true;
      };

      home.packages = with pkgs; [ gnupg ];
    };
}
