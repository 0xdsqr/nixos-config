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

## Quick Start

Use the exported modules directly, or import all exported modules through your own host wrapper.

```nix
{
  inputs.nixos-config.url = "github:0xdsqr/nixos-config";

  outputs =
    { nixos-config, ... }:
    {
      darwinConfigurations.my-mac = nixos-config.lib.darwinSystem {
        hostName = "my-mac";
        modules = [
          nixos-config.darwinModules.obsidian
          ({ ... }: {
            dsqr.darwin.desktop.obsidian.enable = true;

            home-manager.users.alice = {
              imports = [ nixos-config.homeModules.obsidian ];

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

For Home Manager only:

```nix
{ inputs, ... }:
{
  imports = [ inputs.nixos-config.homeModules.obsidian ];

  dsqr.home.desktop.obsidian = {
    enable = true;
    profile = "personal";
  };
}
```

## Obsidian Module

The Darwin module installs the app through Homebrew. The Home Manager module seeds vault folders and config while preserving app-managed state.

| Option | Default | Notes |
| --- | --- | --- |
| `dsqr.darwin.desktop.obsidian.enable` | `false` | Installs the Obsidian cask on Darwin. |
| `dsqr.darwin.desktop.obsidian.package` | `"obsidian"` | Homebrew cask name. |
| `dsqr.home.desktop.obsidian.enable` | `false` | Enables vault bootstrapping. |
| `profile` | `null` | Optional single vault: `"personal"`, `"stablecore"`, or `"work"`. |
| `profilePath` | `null` | Overrides the selected profile path. |
| `defaults.folders` | `Inbox`, `Daily`, `Projects`, `Areas`, `Resources`, `Archive`, `Templates`, `assets` | Folders created in each managed vault. |
| `defaults.files` | Template notes | Files seeded relative to the vault root. |
| `defaults.extraFiles` | Daily Notes and Templates plugin settings | Files seeded under `.obsidian`. |
| `defaults.communityPlugins` | `[]` | Community plugins stay off until explicitly listed. |
| `vaults.<name>.force` | `false` | Existing seeded files are kept unless force is enabled. |

No vault is created unless `dsqr.home.desktop.obsidian.enable = true` and either `profile` or `vaults` is set. Community plugins are not installed by Nix; install them in Obsidian first, then list their ids in `defaults.communityPlugins`.
