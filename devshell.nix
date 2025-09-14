{ nixpkgs, system }:
let
  pkgs = import nixpkgs { inherit system; };
in
{
  # Extra dev packages visible via `nix build .#packages.${system}.default`
  packages.${system}.default = [
    pkgs.bun
    pkgs.python313
  ];

  # Development shell
  devShells.${system}.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Core tools
      nano
      micro
      home-manager
      curl
      wget

      # Build tools
      gnumake
      stdenv.cc
      llvm
      zlib.dev
      openssl.dev
      libffi.dev
      pkg-config
      libyaml.dev
      autoconf
      automake
      libtool
      libuuid
      just

      # Nix tooling
      nixfmt-tree   # replaces nixfmt-rfc-style
      statix
      deadnix
      nil

      # Language runtimes
      bun
      python313
      starship
      zsh
    ];

    shellHook = ''
      # Initialize starship
      if [[ -n "$ZSH_VERSION" ]]; then
        eval "$(starship init zsh)"
      else
        eval "$(starship init bash)"
      fi

      echo "Python version: $(python --version)"
      echo "🚀 dsqr-devbox development shell activated"
    '';

    preferLocalBuild = true;
    shell = "${pkgs.zsh}/bin/zsh";
  };
}
