{ isWSL, inputs, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  imports = [
    # Import eevee module (includes neovim, tmux, git, ghostty, starship, zsh, direnv)
    (inputs.self.homeManagerModules.eevee inputs)
  ];

  # Configure eevee module
  eevee = {
    full_name = "0xdsqr";
    email_address = "dave.dennis@gs.com";
    theme = "tokyo-night";
  };

  # On Linux, enable systemd user services
  systemd.user.startServices = lib.mkIf isLinux "sd-switch";

  # Darwin-specific GPG setup
  programs.zsh.initExtra = lib.mkIf isDarwin ''
    # GPG agent for Darwin
    export GPG_TTY=$(tty)
    if [ -f ~/.gnupg/gpg-agent-info ]; then
      . ~/.gnupg/gpg-agent-info
      export GPG_AGENT_INFO
    fi
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
