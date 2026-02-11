# Module Reference

Full API documentation for all exportable modules.

## eevee (homeManagerModules.eevee)

Portable CLI developer environment for home-manager.

### Options

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

### Language Servers

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

---

## dsqr-nix (nixosModules.dsqr-nix)

Core NixOS system configuration module.

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

---

## dsqr-nix (darwinModules.dsqr-nix)

macOS/Darwin system configuration module.

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

---

## dsqr-proxmox (nixosModules.dsqr-proxmox)

Proxmox VM-specific configuration module.

### What's Included

**Boot Configuration**
- GRUB bootloader for BIOS systems
- Automatic device detection

**Services**
- SSH server with password authentication enabled
- Automatic startup on boot

**Security**
- Basic security hardening
- Passwordless sudo for wheel group

**Timezone**
- America/Chicago timezone

**Networking**
- Configurable hostname and domain
- DHCP or static IP support
- Firewall port management

### Networking Options

```nix
dsqr.proxmox.networking = {
  hostName = "my-vm";                    # Required: machine hostname
  domain = "dsqr.dev";                   # Domain (default: dsqr.dev)

  # Static IP (optional - uses DHCP if not enabled)
  staticIP = {
    enable = false;                      # Enable static IP configuration
    address = "";                        # IP address (e.g., "192.168.50.35")
    prefixLength = 24;                   # Network prefix (default: 24)
    gateway = "192.168.50.1";            # Default gateway
    interface = "enp1s0";                # Network interface
    nameservers = [ "1.1.1.1" "8.8.8.8" ]; # DNS servers
  };

  # Firewall
  firewall.allowedTCPPorts = [ 22 80 443 ]; # TCP ports to open
};
```

### Usage Examples

**Basic VM (DHCP, default ports):**

```nix
dsqr.proxmox.networking = {
  hostName = "gateway";
};
```

**Static IP:**

```nix
dsqr.proxmox.networking = {
  hostName = "cellar";
  staticIP = {
    enable = true;
    address = "192.168.50.35";
  };
};
```

**Custom firewall ports:**

```nix
dsqr.proxmox.networking = {
  hostName = "server";
  firewall.allowedTCPPorts = [ 3000 3001 5432 8080 ];
};
```

### Import Example

```nix
{
  imports = [
    (inputs.dsqr-nix.nixosModules.dsqr-nix inputs)
    (inputs.dsqr-nix.nixosModules.dsqr-proxmox inputs)
  ];

  dsqr.proxmox.networking = {
    hostName = "my-vm";
  };
}
```

Used by all homelab VM configurations (dsqr-server, gateway, cellar, github-runner).
