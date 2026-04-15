{
  agenix,
  nixpkgs,
  system,
}:
let
  pkgs = import nixpkgs { inherit system; };
  agenixPackage = agenix.packages.${system}.default;
in
pkgs.mkShell {
  packages = with pkgs; [
    # Language runtimes
    bun
    nodejs_24
    python313
    uv

    # Core CLI tools
    biome
    git
    nano
    micro
    treefmt
    curl
    wget

    # Nix and homelab tooling
    home-manager
    just
    pulumi
    pulumiPackages.pulumi-nodejs
    agenixPackage
    sops
    age
    ssh-to-age

    # Build and compilation support
    gnumake
    stdenv.cc
    llvm
    pkg-config
    autoconf
    automake
    libtool
    libuuid
    zlib.dev
    openssl.dev
    libffi.dev
    libyaml.dev

    # Nix quality tools
    nixfmt
    nixfmt-tree
    statix
    deadnix
    nil
  ];

  shellHook = ''
    echo "Python version: $(python --version)"
    echo "Development shell activated."
  '';
}
