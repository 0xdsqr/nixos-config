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
  eevee = (import ../eevee-defaults.nix) // {
    opencode.enable = true;
  };

  # On Linux, enable systemd user services
  systemd.user.startServices = lib.mkIf isLinux "sd-switch";

  # jujutsu (jj) - Git-compatible VCS
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = config.eevee.full_name;
        email = config.eevee.email_address;
      };
    };
  };

  # Darwin-specific GPG setup
  programs.zsh.initContent = lib.mkIf isDarwin ''
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
