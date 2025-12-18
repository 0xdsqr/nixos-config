# Detect OS
uname := `uname`

# Configuration names
NIXNAME := if uname == "Darwin" { "devbox-macbook-pro-m1" } else { "github-runner-vm-x86_64" }

# Default command
default: switch

# Format nix files
format:
    nix fmt .

# Switch system configuration
switch:
    #!/usr/bin/env bash
    if [[ "{{ uname }}" == "Darwin" ]]; then
        echo "Building Darwin configuration: {{ NIXNAME }}"
        NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.{{ NIXNAME }}.system"
        echo "Switching to Darwin configuration..."
        sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$(pwd)#{{ NIXNAME }}"
    else
        echo "Switching to NixOS configuration: {{ NIXNAME }}"
        sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --impure --flake ".#{{ NIXNAME }}"
    fi

# Test system configuration
test:
    #!/usr/bin/env bash
    if [[ "{{ uname }}" == "Darwin" ]]; then
        echo "Testing Darwin configuration: {{ NIXNAME }}"
        NIXPKGS_ALLOW_UNFREE=1 nix build --impure ".#darwinConfigurations.{{ NIXNAME }}.system"
        sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild test --impure --flake "$(pwd)#{{ NIXNAME }}"
    else
        echo "Testing NixOS configuration: {{ NIXNAME }}"
        sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild test --impure --flake ".#{{ NIXNAME }}"
    fi

# Clean old generations and collect garbage
clean:
    #!/usr/bin/env bash
    echo "Running nix garbage collection..."
    if [[ "{{ uname }}" == "Darwin" ]]; then
        nix-collect-garbage -d
        nix-store --optimise
    else
        sudo nix-collect-garbage -d
        sudo nix-store --optimise
    fi
