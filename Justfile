# Justfile for dsqr-devbox
# Variables can be overridden, e.g. `just NIXNAME=myhost switch`

# Default config name
NIXNAME := "vm-intel"

# Detect OS once
uname := `uname`

# Switch system configuration
switch:
    if [ "{{uname}}" = "Darwin" ]; then
        NIXPKGS_ALLOW_UNFREE=1 \
        nix build --impure \
          --extra-experimental-features nix-command \
          --extra-experimental-features flakes \
          ".#darwinConfigurations.${NIXNAME}.system"
        sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$$(pwd)#${NIXNAME}"
    else
        sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 \
        nixos-rebuild switch --impure --flake ".#${NIXNAME}"
    fi

# Test system configuration
test:
    if [ "{{uname}}" = "Darwin" ]; then
        NIXPKGS_ALLOW_UNFREE=1 nix build --impure ".#darwinConfigurations.${NIXNAME}.system"
        sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild test --impure --flake "$$(pwd)#${NIXNAME}"
    else
        sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 \
        nixos-rebuild test --impure --flake ".#${NIXNAME}"
    fi

# Format Nix files
format:
    nix develop -c nix fmt
