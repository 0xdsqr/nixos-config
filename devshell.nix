{ nixpkgs, system }:
let
  pkgs = import nixpkgs { inherit system; };
in
{
  # import the dev pkgs from compilation
  packages.${system}.default = [
    pkgs.bun
    pkgs.python313
  ];

  # Create a development shell
  devShells.${system}.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Core packages
      nano
      micro
      home-manager
      curl
      wget

      # Development tools
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

      # Nix development tools
      nixfmt-rfc-style
      nixfmt-tree
      statix
      deadnix
      nil

      # Secrets management
      sops
      age
      ssh-to-age

      # Language runtimes
      bun
      python313
      starship
      zsh
    ];

    shellHook = ''
      echo "Python version: $(python --version)"
      echo "🚀 Development shell activated, you can now compile things"
    '';

    # Prefer zsh as the shell
    preferLocalBuild = true;
    shell = "${pkgs.zsh}/bin/zsh";
  };
}
