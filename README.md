<div align="center">
<img src="./.github/assets/nixos-homelab.svg" alt="Owl watching over homelab servers" width="200"/>

<p align="center">
  <a href="https://github.com/0xdsqr/nixos-config"><img src="https://img.shields.io/badge/github-nixos--config-blue?style=for-the-badge&logo=github" alt="GitHub"></a>
  <a href="#"><img src="https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=apple&logoColor=white" alt="nix-darwin"></a>
  <a href="#"><img src="https://img.shields.io/badge/machines-8-7EBAE4?style=for-the-badge" alt="8 Machines"></a>
</p>

**Modular, portable NixOS/nix-darwin configuration for homelab servers and development machines.**

*A flake-based setup managing 8 machines with shared modules and zero configuration drift.*
</div>

## ⇁ Why This Exists

I got tired of my machines drifting apart. Spend a week setting up Neovim on my Mac, then have to remember what I did when I spin up a new VM. Copy dotfiles around, forget packages, realize my Git config is different everywhere. It sucked.

## ⇁ What It Does

One flake, 8 machines, zero drift:
- **eevee module** - Same CLI setup everywhere (Neovim, Git, Zsh, tmux)
- **Works on macOS and Linux** - Same config, different platforms
- **Homelab ready** - Running my entire homelab (databases, monitoring, home automation)
- **Just import it** - All modules are exportable if you want to use them

## ⇁ Installation

**Prerequisites:** Nix with flakes enabled

### NixOS

```bash
# Clone the repo
git clone https://github.com/yourusername/nixos-config.git ~/.config/nixos-config
cd ~/.config/nixos-config

# Edit Justfile to set your machine name (line 5)
# NIXNAME := "your-machine-name"

# Apply configuration
just switch
```

### macOS (nix-darwin)

```bash
# Install nix-darwin first
nix run nix-darwin -- switch --flake ~/.config/nixos-config

# Clone the repo
git clone https://github.com/yourusername/nixos-config.git ~/.config/nixos-config
cd ~/.config/nixos-config

# Edit Justfile to set your machine name
# NIXNAME := "devbox-macbook-pro-m1"

# Apply configuration
just switch
```

### As a Module (Import into Your Flake)

```nix
{
  inputs.dsqr-nix.url = "github:yourusername/nixos-config";

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

## ⇁ Quick Start

**Configure your machine:**

```nix
# In machines/my-machine.nix
eevee = {
  full_name = "0xdsqr";
  email_address = "dave.dennis@gs.com";
  theme = "tokyo-night";

  # Optional: Exclude packages you don't want
  nixos.exclude_packages = [ "chromium" "spotify" ];
  darwin.exclude_casks = [ "discord" ];
};
```

**Apply changes:**

```bash
just switch    # Build and activate configuration
just test      # Test without activating
just format    # Format all Nix files with alejandra
just clean     # Garbage collect old generations
```

**Override machine name per-command:**

```bash
NIXNAME=gateway-vm-x86_64 just switch
```

That's it! Your entire environment (Neovim, Git, Zsh, tmux, packages) is configured.

## ⇁ What is eevee?

**eevee** is the core of this config - a portable home-manager module providing a complete CLI developer experience:

- 🎨 **Neovim 0.11+** - Native LSP (TypeScript, Go, Python, Nix), no Mason/plugin managers
- 🔐 **Git + GPG** - Commit signing configured with your eevee name/email
- ⚡ **Zsh + Starship** - Custom purple prompt theme with syntax highlighting
- 🖥️ **Ghostty** - GPU-accelerated terminal (Linux only)
- 🔧 **Tmux** - Terminal multiplexing with Space prefix
- 📦 **Direnv** - Automatic nix-direnv integration

**Why "eevee"?** Like the Pokemon that evolves into different forms, eevee adapts to any environment (macOS, Linux, VM, physical hardware) while keeping your tooling consistent.

**Zero runtime package managers.** Everything installed via Nix. Pure, reproducible, portable.

## ⇁ API Reference

<details><summary><strong>eevee Module (homeManagerModules.eevee)</strong></summary>

**Portable CLI developer environment for home-manager.**

### Configuration Options

```nix
eevee = {
  full_name = "Your Name";           # Required: Used for Git commits
  email_address = "you@example.com"; # Required: Used for Git commits
  theme = "tokyo-night";             # Required: Theme (currently only tokyo-night)

  # Optional exclusions
  nixos.exclude_packages = [ ];      # List of system packages to exclude
  darwin.exclude_casks = [ ];        # List of Homebrew casks to exclude (macOS)
};
```

### What's Included

**Neovim 0.11+**
- Native LSP using `vim.lsp.config` (no lspconfig plugin)
- Language servers: typescript, biome, gopls, pyright, nil
- Plugins: Telescope, Treesitter, blink-cmp, conform.nvim, gitsigns, lualine, which-key, nvim-tree
- Format on save with conform.nvim
- Tokyo Night theme
- No Mason, no lazy.nvim - everything via Nix

**Git Configuration**
- GPG signing enabled (key: 6908FE142198DB65)
- Uses eevee.full_name and eevee.email_address
- GitHub CLI (gh) integration
- GPG agent with pinentry-curses (Linux) or manual setup (Darwin)

**Terminal Environment**
- **Ghostty** - GPU-accelerated terminal (Linux only)
- **Zsh** - Completions, autosuggestions, syntax highlighting
- **Starship** - Custom purple (#C8A2D0) prompt with git integration
- **Tmux** - Space prefix, mouse enabled, Dracula theme
- **Direnv** - Automatic nix-direnv for project environments

### Language Servers Included

| Language | LSP | Formatter | Tools |
|----------|-----|-----------|-------|
| TypeScript/JavaScript | typescript-language-server | biome | typescript, biome |
| Go | gopls | gofumpt | go, gotools |
| Python | pyright | ruff | python3, ruff |
| Nix | nil | nixfmt-rfc-style | - |

### Import Example

```nix
{
  home-manager.users.youruser = {
    imports = [ (inputs.dsqr-nix.homeManagerModules.eevee inputs) ];

    eevee = {
      full_name = "Your Name";
      email_address = "you@example.com";
      theme = "tokyo-night";
    };
  };
}
```

</details>

<details><summary><strong>dsqr-nix Module (nixosModules.dsqr-nix)</strong></summary>

**Core NixOS system configuration module.**

### What's Included

**System Services**
- **1Password** - CLI + GUI with polkit integration (dsqr user only)
- **Docker + Podman** - Both container runtimes running side-by-side
- **Audio** - PipeWire with ALSA, PulseAudio, and JACK support
- **Networking** - NetworkManager, systemd-resolved, Bluetooth

**System Packages**

*Essential (cannot be excluded):*
- Core: git, vim, alejandra, fzf, zoxide, ripgrep, eza, fd
- Utilities: curl, unzip, wget, gnumake
- Linux GUI: libnotify, nautilus, blueberry, clipse

*Discretionary (can be excluded via `eevee.nixos.exclude_packages`):*
- TUIs: lazygit, lazydocker, btop, fastfetch
- Dev tools: gh, cachix
- Containers: docker-compose, ffmpeg
- GUI apps: chromium, obsidian, vlc, signal-desktop, spotify

**Fonts**
- Noto fonts (sans, serif, mono, emoji)
- CaskaydiaMono Nerd Font

### Import Example

```nix
{
  imports = [
    (inputs.dsqr-nix.nixosModules.dsqr-nix inputs)
  ];

  # Exclude unwanted packages
  eevee.nixos.exclude_packages = [ "chromium" "spotify" "vlc" ];
}
```

</details>

<details><summary><strong>dsqr-nix Module (darwinModules.dsqr-nix)</strong></summary>

**macOS/Darwin system configuration module.**

### What's Included

**Homebrew Cask Management**

All casks are discretionary and can be excluded via `eevee.darwin.exclude_casks`:

- **Terminal**: ghostty
- **Apps**: spotify, 1password, cleanshot, discord, raycast, obsidian, vlc, signal, typora, dropbox, chromium

**Note:** CLI packages are still managed through Nix (not Homebrew). Only GUI apps use Homebrew casks.

### System Settings

- **Shell**: Zsh enabled system-wide
- **State Version**: 5

### Import Example

```nix
{
  imports = [
    (inputs.dsqr-nix.darwinModules.dsqr-nix inputs)
  ];

  # Exclude unwanted casks
  eevee.darwin.exclude_casks = [ "discord" "spotify" ];
}
```

</details>

<details><summary><strong>dsqr-proxmox Module (nixosModules.dsqr-proxmox)</strong></summary>

**Proxmox VM-specific configuration module.**

### What's Included

**Boot Configuration**
- GRUB bootloader for BIOS systems
- Automatic device detection

**Services**
- SSH server with password authentication enabled
- Automatic startup on boot

**Security**
- Basic security hardening
- Firewall configuration

**Timezone**
- Configured timezone settings

### Import Example

```nix
{
  imports = [
    (inputs.dsqr-nix.nixosModules.dsqr-nix inputs)
    (inputs.dsqr-nix.nixosModules.dsqr-proxmox inputs)
  ];
}
```

Used by all homelab VM configurations (dsqr-server, gateway, hoo, smart-home).

</details>

## ⇁ Development

**Requirements:** Nix with flakes enabled

### Dev Shell

```bash
nix develop    # Enter shell with formatters and linters
direnv allow   # Auto-load dev shell on cd (recommended)
```

**Includes:**
- nixfmt, alejandra - Nix formatters
- statix, deadnix - Nix linters
- nil - Nix language server

### Just Commands

| Command | Description |
|---------|-------------|
| `just switch` | Build and activate configuration (auto-detects platform) |
| `just test` | Test configuration without switching |
| `just format` | Format all Nix files with alejandra |
| `just clean` | Garbage collect old generations |

### Changing Target Machine

Edit `Justfile` line 5:

```just
NIXNAME := if uname == "Darwin" { "your-darwin-machine" } else { "your-nixos-machine" }
```

Or override per-command:

```bash
NIXNAME=gateway-vm-x86_64 just switch
```

## ⇁ Contributing

This runs my homelab and personal machines, but if you're using it or want to improve something, **open a PR and I'll take a look!**

If there's a module you think could be broken out into a separate repo for easier reuse (like eevee), let me know - happy to split things up if there's interest.

**Using this config?** Fork it and make it your own. That's what it's here for.

## ⇁ Thanks

Learned a ton from these incredible Nix configurations:

- [tobi/dotnix](https://github.com/tobi/dotnix) - Clean modular structure and Darwin inspiration
- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config/) - Flake architecture and VM setups
- [henrysipp/omarchy-nix](https://github.com/henrysipp/omarchy-nix) - Home-manager patterns and theming ideas

All MIT licensed. Standing on the shoulders of giants here. Thanks for sharing your work!

## ⇁ License

MIT - Do whatever you want with it.
