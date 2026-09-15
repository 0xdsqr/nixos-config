# T3 Code

This package tracks stable releases of [pingdotgg/t3code](https://github.com/pingdotgg/t3code).
It reuses the nixpkgs desktop/CLI packaging and resource monitor, with independent
release and dependency pins so updates do not need a full nixpkgs update.

Enable it in a Home Manager configuration:

```nix
dsqr.home.t3code.enable = true;
```

The package supplies the T3 Code desktop app, `t3code-desktop`, and the `t3`
CLI/web server. Provider CLIs use the existing shell environment. Configure the
app through its UI or the upstream `programs.t3code` Home Manager options.

The nightly `update-agents` workflow checks for new stable releases and updates
the source, pnpm dependency, and resource-monitor Cargo hashes. `build-agents`
then builds and caches the package on Linux and Apple Silicon macOS. This follows
stable releases; it does not opt into T3 Code's prerelease/nightly channel.

To update or build this package alone:

```sh
nix run .#update-pins -- t3code
nix build .#t3code
```

Updating these pins does not activate hosts. Rebuild after pulling the update;
downstream flakes such as Stablecore must also update their `nixos-config` input.
