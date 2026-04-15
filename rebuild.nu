#!/usr/bin/env nu

let hosts = {
  devbox-macbook-pro: darwin
  exo-mac-mini-01: darwin
  exo-mac-mini-02: darwin
  beacon: nixos
  gateway: nixos
  khaos: nixos
}

def main [
  host: string # Host to rebuild.
  --dry-run    # Print the command instead of running it.
  ...args: string # Extra flags passed to darwin-rebuild or nixos-rebuild.
]: nothing -> nothing {
  let kind = ($hosts | get --optional $host)

  if $kind == null {
    let available = ($hosts | columns | sort | str join ", ")
    print --stderr $"error: unknown host '($host)'"
    print --stderr $"known hosts: ($available)"
    exit 1
  }

  let command = if $kind == "darwin" {
    [darwin-rebuild switch --flake $".#($host)"] | append $args
  } else {
    [sudo nixos-rebuild switch --flake $".#($host)"] | append $args
  }

  if $dry_run {
    print ($command | str join " ")
    return
  }

  if $kind == "darwin" {
    ^darwin-rebuild switch --flake $".#($host)" ...$args
  } else {
    ^sudo nixos-rebuild switch --flake $".#($host)" ...$args
  }
}
