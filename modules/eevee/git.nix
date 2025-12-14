{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "0xdsqr";
    userEmail = "me@dsqr.dev";
    signing = {
      key = "6908FE142198DB65";
      signByDefault = true;
    };
    aliases = {
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # Use terminal for askpass
      credential.helper = "store"; # want to make this more secure
      github.user = "0xdsqr";
      push.default = "tracking";
      init.defaultBranch = "main";
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

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableSshSupport = true;
  };
  home.packages = with pkgs; [
    gnupg
  ];
}
