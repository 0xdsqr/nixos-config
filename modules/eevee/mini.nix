inputs:
{ ... }:
{
  imports = [
    ./tmux.nix
    ./direnv.nix
    ./zsh.nix
    ./starship.nix
    ./git.nix
    (import ./neovim-mini.nix inputs)
  ];
}
