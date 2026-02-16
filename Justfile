# Detect OS
uname := `uname`

# Configuration names
NIXNAME := if uname == "Darwin" { "devbox-macbook-pro-m1" } else { "github-runner-vm-x86_64" }
# Auto-detect hostname, fallback to dsqr-mini-001
MINI_NAME := if uname == "Darwin" { `scutil --get LocalHostName 2>/dev/null || echo "dsqr-mini-001"` } else { "dsqr-mini-001" }

# Default command
default: switch

# Install Determinate Nix (macOS/Linux)
bootstrap-determinate:
    #!/usr/bin/env bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

# Backward-compatible alias
bootstrap: bootstrap-determinate

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

# Build mini-cluster darwin configuration (uses HostName by default)
build-mini:
    #!/usr/bin/env bash
    if [[ "{{ uname }}" == "Darwin" ]]; then
        echo "Building mini configuration: {{ MINI_NAME }}"
        NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.{{ MINI_NAME }}.system"
    else
        echo "build-mini is only supported on Darwin"
        exit 1
    fi

# Switch mini-cluster darwin configuration (uses HostName by default)
switch-mini:
    #!/usr/bin/env bash
    if [[ "{{ uname }}" == "Darwin" ]]; then
        echo "Building mini configuration: {{ MINI_NAME }}"
        NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.{{ MINI_NAME }}.system"
        echo "Switching to mini configuration..."
        sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$(pwd)#{{ MINI_NAME }}"
    else
        echo "switch-mini is only supported on Darwin"
        exit 1
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
    echo "Cleaning old generations and running garbage collection..."
    if [[ "{{ uname }}" == "Darwin" ]]; then
        # Delete old system generations (keep current)
        sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old 2>/dev/null || true
        # Delete old user generations (keep last 5)
        nix-env --delete-generations +5 2>/dev/null || true
        # Garbage collect (user store)
        nix-collect-garbage --delete-older-than 7d
        # Garbage collect (system store) 
        sudo nix-collect-garbage --delete-older-than 7d
        # Optimise store (dedup)
        echo "Optimising nix store (this may take a while)..."
        nix store optimise
    else
        sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old 2>/dev/null || true
        nix-env --delete-generations +5 2>/dev/null || true
        sudo nix-collect-garbage --delete-older-than 7d
        echo "Optimising nix store (this may take a while)..."
        sudo nix store optimise
    fi
    echo "Done."
