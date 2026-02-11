{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # GPG TTY for signing commits
      export GPG_TTY=$(tty)
    '';
  };
}
