# nixos-config

Opinionated NixOS configuration - Modular setup for my VMs, dev boxes, and servers

## External Usage

### Available Modules

| Module                        | Platform       | Description                     | Usage                                               |
| ----------------------------- | -------------- | ------------------------------- | --------------------------------------------------- |
| `nixosModules.dsqr-nix`       | NixOS          | Full NixOS system configuration | System-level config with themes, packages, services |
| `nixosModules.dsqr-proxmox`   | Proxmox        | Proxmox-specific NixOS setup    | Boot, security, services for Proxmox VMs            |
| `darwinModules.dsqr-nix`      | macOS          | Darwin system configuration     | Homebrew, packages, system settings                 |
| `homeManagerModules.dsqr-nix` | Cross-platform | Home-manager user configuration | Dotfiles, themes, user applications                 |

### Quick Start

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dsqr-nix.url = "github:yourusername/nixos-config";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { nixpkgs, dsqr-nix, home-manager, ... }: {
    # NixOS Configuration
    nixosConfigurations.my-system = nixpkgs.lib.nixosSystem {
      modules = [
        dsqr-nix.nixosModules.dsqr-nix
        home-manager.nixosModules.home-manager
        {
          dsqrDevbox = {
            theme = "kanagawa";
            nixos.exclude_packages = [ pkgs.spotify ];
          };
          home-manager.users.myuser = {
            imports = [ dsqr-nix.homeManagerModules.dsqr-nix ];
          };
        }
      ];
    };

    # Darwin Configuration
    darwinConfigurations.my-mac = darwin.lib.darwinSystem {
      modules = [
        dsqr-nix.darwinModules.dsqr-nix
        home-manager.darwinModules.home-manager
        {
          dsqrDevbox = {
            theme = "tokyo-night";
            darwin.exclude_casks = [ "spotify" ];
          };
          home-manager.users.myuser = {
            imports = [ dsqr-nix.homeManagerModules.dsqr-nix ];
          };
        }
      ];
    };
  };
}
```

### Configuration Options

- **`theme`**: `"tokyo-night"` | `"kanagawa"` | `"everforest"` | `"nord"` | `"gruvbox"` | `"catppuccin"` | `"generated_light"` | `"generated_dark"`
- **`nixos.exclude_packages`**: List of packages to exclude from NixOS
- **`darwin.exclude_casks`**: List of Homebrew casks to exclude from Darwin
- **`theme_overrides.wallpaper_path`**: Custom wallpaper for generated themes

## Development Usage

### Darwin (macOS)

```bash
export NIXNAME=devbox-macbook-pro-m1
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$(pwd)#${NIXNAME}"
```

### NixOS (Linux VM)

```bash
export NIXNAME=devbox-vm-x86_64
sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --impure --flake ".#${NIXNAME}"
```

### Using Just (recommended)

```bash
# Auto-detects platform and switches configuration
just switch

# Test configuration without switching
just test

# Format nix files
just format

# Lint nix files for anti-patterns
just lint

# Find and remove dead code
just deadcode

# Check nix files (lint + deadcode)
just check

# Fix all issues (format + check)
just fix
```

## Thanks

A lot of reference for the work done is taken/reference from some of these repositories.

- https://github.com/tobi/dotnix
- https://github.com/mitchellh/nixos-config/
- https://github.com/henrysipp/omarchy-nix

Which all under or were at the time MIT license, thanks to them for the great work.
