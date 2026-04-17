{ agenix, pkgs, self, ... }:
let
  agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  moonshotPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.moonshot;
in
{
  config.environment.systemPackages = with pkgs; [
    agenixPackage
    moonshotPackage
    postgresql
    git
    just
    vim
    alejandra
    fzf
    zoxide
    ripgrep
    eza
    fd
    curl
    unzip
    wget
    gnumake
    screen
    tmux
    lazygit
    lazydocker
    btop
    fastfetch
    gh
    cachix
    vscode
    docker-compose
    ffmpeg
  ];
}
