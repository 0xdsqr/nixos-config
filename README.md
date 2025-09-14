# nixos-config
Opinionated NixOS configuration - Modular setup for my VMs, dev boxes, and servers


## Blah

```bash
export NIXNAME=devbox-macbook-pro-m1
export NIXNAME=devbox-vm-x86_64
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$(pwd)#${NIXNAME}"
```

## Thanks

A lot of refernce for the work done is taken/reference from some of these repositories.

- https://github.com/tobi/dotnix
- https://github.com/mitchellh/nixos-config/
- https://github.com/henrysipp/omarchy-nix

Which all under or were at the time MIT license, thanks to them for the great work. 