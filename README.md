<div align="center">
<p align="center">
  <a href="https://github.com/0xdsqr/nixos-config/actions/workflows/check.yml"><img src="https://img.shields.io/github/actions/workflow/status/0xdsqr/nixos-config/check.yml?branch=main&style=for-the-badge&logo=github&label=check" alt="check"></a>
  <a href="https://github.com/0xdsqr/nixos-config/commits/main"><img src="https://img.shields.io/github/last-commit/0xdsqr/nixos-config?style=for-the-badge" alt="last commit"></a>
  <a href="https://wiki.nixos.org/wiki/Flakes"><img src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge" alt="Nix Flakes Ready"></a>
  <a href="#"><img src="https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=apple&logoColor=white" alt="nix-darwin"></a>
</p>

This is my nixos-config. There are many like it, but this one is mine.
</div>

## Getting Started

Add the flake as an input:

```nix
{
  inputs.nixos-config.url = "github:0xdsqr/nixos-config";
}
```

Use one module, a few modules, or your own profile wrapper around them. Modules are exported by platform surface:

| Surface | Export |
| --- | --- |
| Shared Nix modules | `commonModules` |
| nix-darwin modules | `darwinModules` |
| Home Manager modules | `homeModules` |
| NixOS modules | `nixosModules` |
| Packages and apps | `packages`, `apps` |

## Darwin Host

Use the helper if you want the same nix-darwin, Home Manager, agenix, and nix-homebrew wiring this repo uses:

```nix
{
  outputs =
    { nixos-config, ... }:
    {
      darwinConfigurations.my-mac = nixos-config.lib.darwinSystem {
        hostName = "my-mac";
        hostMeta = nixos-config.lib.mkHostMeta {
          class = "darwin";
          path = ./.;
          system = "aarch64-darwin";
        };

        modules = [
          nixos-config.darwinModules.obsidian

          ({ ... }: {
            dsqr.darwin.desktop.obsidian.enable = true;

            home-manager.users.alice = {
              imports = [
                nixos-config.homeModules.git
                nixos-config.homeModules.obsidian
              ];

              dsqr.home.versionControl.enable = true;
              dsqr.home.desktop.obsidian = {
                enable = true;
                profile = "personal";
              };
            };
          })
        ];
      };
    };
}
```

## Home Manager Only

Home Manager modules can be used without nix-darwin or NixOS:

```nix
{
  outputs =
    {
      home-manager,
      nixos-config,
      nixpkgs,
      ...
    }:
    {
      homeConfigurations.alice = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;

        modules = [
          nixos-config.homeModules.git
          nixos-config.homeModules.neovim
          nixos-config.homeModules.obsidian

          ({ ... }: {
            home.username = "alice";
            home.homeDirectory = "/Users/alice";

            dsqr.home.versionControl.enable = true;
            dsqr.home.neovim.enable = true;
            dsqr.home.desktop.obsidian = {
              enable = true;
              profile = "personal";
            };
          })
        ];
      };
    };
}
```

## NixOS Host

NixOS modules can be imported the same way:

```nix
{
  outputs =
    { nixos-config, ... }:
    {
      nixosConfigurations.my-server = nixos-config.lib.nixosSystem {
        hostName = "my-server";
        hostMeta = nixos-config.lib.mkHostMeta {
          class = "nixos";
          path = ./.;
          system = "x86_64-linux";
        };

        modules = [
          nixos-config.nixosModules.openssh
          nixos-config.nixosModules.tailscale

          ({ ... }: {
            dsqr.nixos.openssh.enable = true;
            dsqr.nixos.tailscale.enable = true;
          })
        ];
      };
    };
}
```

## Features

Most modules are opt-in. Importing a module gives you its options; behavior usually starts when you set its `enable` option.

| Feature | Surface | Default | What You Opt Into |
| --- | --- | --- | --- |
| Common Nix defaults | `commonModules.*` | Import only | Nix settings, nixpkgs policy, fonts, Home Manager integration, and shared package policy. |
| Home shell and editor | `homeModules.git`, `homeModules.neovim`, `homeModules.nushell`, `homeModules.starship`, `homeModules.direnv`, `homeModules.ssh`, `homeModules.xdg` | Off unless enabled | Reusable Home Manager modules for CLI and editor setup. |
| Home package groups | `homeModules.packages-*` | Off unless enabled | Containers, databases, debugging, Kubernetes, media, Node, shell utilities, and signing tools. |
| Darwin desktop apps | `darwinModules.*`, selected `homeModules.*` | Off unless enabled | Ghostty, Hammerspoon, window manager, browser policy, Slack, Signal, Discord, Zoom, Lapdog, and related app config. |
| Obsidian | `darwinModules.obsidian`, `homeModules.obsidian` | App off, vault bootstrap off | Darwin cask install plus optional Home Manager vault seeding; community plugins stay off by default. |
| NixOS services | `nixosModules.*` | Off unless enabled | OpenSSH, Tailscale, Restic, PostgreSQL, Redis, RustFS, kubeadm, monitoring, hardware reports, and installer helpers. |
| Monitoring | `darwinModules.grafana-*`, `nixosModules.monitoring-*` | Off unless enabled | Grafana, Alloy, Loki, and Prometheus plumbing without private defaults baked into exported modules. |
| Profiles | `profiles/*` | Explicit import only | Opinionated host and fleet composition such as `profiles/dsqr` and `profiles/mini-server`; profiles are not generic module exports. |
| Apply tool | `packages.<system>.apply`, `apps.<system>.apply` | Available when built or run | Local helper for applying host configs from the flake. |

### Apply a host configuration

`apply` uses the flake-pinned Nix, `nixos-rebuild`, and `darwin-rebuild` tools. SSH host names are passed through unchanged so aliases keep their configured user, identity, proxy, and connection options.

```sh
# Apply the matching configuration to the current machine.
nix run .#apply -- srv-lx-k8s-master-01

# Build on khaos and activate the Kubernetes control-plane host.
nix run .#apply -- --build-host srv-lx-khaos srv-lx-k8s-master-01

# Exercise the same remote-build path without activating it.
nix run .#apply -- --dry-run --build-host srv-lx-khaos srv-lx-k8s-master-01

# Override an identity only when the SSH alias does not already provide one.
nix run .#apply -- --identity ~/.ssh/dsqr_homelab_ed25519 --remote srv-lx-beacon
```

Use `--ask-sudo-password` when remote activation cannot use passwordless sudo. Run `nix run .#apply -- --help` for the complete interface.

Explore the current exports:

```sh
nix flake show github:0xdsqr/nixos-config
nix eval github:0xdsqr/nixos-config#homeModules --apply builtins.attrNames --json
```
