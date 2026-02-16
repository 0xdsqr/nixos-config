{ inputs, ... }:
{
  pkgs,
  ...
}:
let
  gitProfile = import ../eevee-defaults.nix;
in
{
  programs.zsh.enable = true;
  programs.starship.enable = true;
  programs.direnv.enable = true;
  programs.tmux.enable = true;

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };

  programs.git = {
    enable = true;
    signing.signByDefault = false;
    settings = {
      user = {
        name = gitProfile.full_name;
        email = gitProfile.email_address;
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "tracking";
      credential.helper = "osxkeychain";
      github.user = "0xdsqr";
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
