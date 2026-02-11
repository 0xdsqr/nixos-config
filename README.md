<div align="center">
<img src="./.github/assets/nixos-homelab.svg" alt="Owl watching over homelab servers" width="200"/>

<p align="center">
  <a href="https://github.com/0xdsqr/nixos-config"><img src="https://img.shields.io/badge/github-nixos--config-blue?style=for-the-badge&logo=github" alt="GitHub"></a>
  <a href="#"><img src="https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=apple&logoColor=white" alt="nix-darwin"></a>
</p>

**Modular, portable NixOS/nix-darwin configuration for homelab servers and development machines.**

*A flake-based setup with shared modules and zero configuration drift.*
</div>

## Why This Exists

I got tired of my machines drifting apart. Spend a week setting up Neovim on my Mac, then have to remember what I did when I spin up a new VM. Copy dotfiles around, forget packages, realize my Git config is different everywhere. It sucked.

## Machines

| Machine | Platform | Purpose |
|---------|----------|---------|
| devbox-macbook-pro-m1 | Darwin | Daily driver |
| devbox-vm-x86_64 | NixOS | Development VM |
| devbox-usb-x86_64 | NixOS | Portable USB install |
| gateway-vm-x86_64 | NixOS | Network gateway |
| dsqr-server-vm-x86_64 | NixOS | Main homelab server |
| cellar-vm-x86_64 | NixOS | Storage/backup |
| media-server-vm-x86_64 | NixOS | Media services |
| github-runner-vm-x86_64 | NixOS | CI runner |

## Quick Start

**Prerequisites:** Nix with flakes enabled

```bash
# Clone
git clone https://github.com/0xdsqr/nixos-config.git ~/.config/nixos-config
cd ~/.config/nixos-config

# Set your machine name in Justfile (line 5)
# NIXNAME := "your-machine-name"

# Apply
just switch
```

**macOS users:** Install nix-darwin first with `nix run nix-darwin -- switch --flake ~/.config/nixos-config`

## What is eevee?

**eevee** is a portable home-manager module that gives you a complete CLI dev environment:

- **Neovim 0.11+** - Native LSP (TypeScript, Go, Python, Nix), no Mason/plugin managers
- **Git + GPG** - Commit signing configured with your name/email
- **Zsh + Starship** - Custom purple prompt with syntax highlighting
- **Tmux** - Terminal multiplexing with Space prefix
- **Direnv** - Automatic nix-direnv integration

```nix
eevee = {
  full_name = "Your Name";
  email_address = "you@example.com";
  theme = "tokyo-night";
};
```

## Using as a Module

Import into your own flake:

```nix
{
  inputs.dsqr-nix.url = "github:0xdsqr/nixos-config";

  outputs = { nixpkgs, dsqr-nix, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        (dsqr-nix.nixosModules.dsqr-nix inputs)
        {
          home-manager.users.myuser = {
            imports = [ (dsqr-nix.homeManagerModules.eevee inputs) ];
            eevee = {
              full_name = "Your Name";
              email_address = "you@example.com";
              theme = "tokyo-night";
            };
          };
        }
      ];
    };
  };
}
```

## Commands

```bash
just switch    # Build and activate configuration
just test      # Test without activating
just format    # Format all Nix files
just clean     # Garbage collect old generations
```

Override machine per-command: `NIXNAME=gateway-vm-x86_64 just switch`

## Documentation

- **[.github/assets/modules.md](./.github/assets/modules.md)** - Full API reference for eevee, dsqr-nix, and dsqr-proxmox modules
- **[.github/assets/secrets.md](./.github/assets/secrets.md)** - SOPS/age secrets management guide

## Development

```bash
nix develop    # Enter dev shell with formatters/linters
nix fmt        # Format all files (Nix, TypeScript, JavaScript)
```

## License

MIT
