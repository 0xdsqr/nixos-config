{
  flake.darwinModules.packages =
    { agenix, pkgs, ... }:
    let
      agenixPackage = agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      homebrew.brews = [ "deno" ];

      environment.systemPackages = with pkgs; [
        agenixPackage
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
        rsync
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
        docker-compose
        ffmpeg
      ];
    };
}
