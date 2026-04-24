# `mgmt`

`mgmt` is a small Nushell-first CLI for working on this `nixos-config` repository.

It is intentionally narrow in scope. Most commands are thin wrappers around normal local workflows, with a small amount of repo-specific behavior layered on top where that makes the day-to-day flow cleaner.

The package is meant to be used locally alongside Nix and NixOS. If you already know the underlying commands, nothing here is magic; it just gives this repo a consistent management entrypoint.
