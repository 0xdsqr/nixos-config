set positional-arguments

default:
  @just --list

hosts:
  @printf '%s\n' \
    'nixos: dsqr-server-vm-x86_64 gateway-vm-x86_64 github-runner-vm-x86_64' \
    'darwin: devbox-macbook-pro-m1 dsqr-mini-001 dsqr-mini-002'

host target='':
  #!/usr/bin/env bash
  set -euo pipefail

  target="${1:-${NIXNAME:-}}"
  os="$(uname -s)"

  if [[ -z "$target" ]]; then
    if [[ "$os" == "Darwin" ]]; then
      local_name="$(scutil --get LocalHostName 2>/dev/null || true)"
      case "$local_name" in
        dsqr-mini-001|dsqr-mini-002) target="$local_name" ;;
        Davids-MacBook-Pro) target="devbox-macbook-pro-m1" ;;
        *) target="devbox-macbook-pro-m1" ;;
      esac
    else
      target="$(hostname -s 2>/dev/null || hostname)"
    fi
  fi

  case "$target" in
    github-runner) target="github-runner-vm-x86_64" ;;
    gateway) target="gateway-vm-x86_64" ;;
    server) target="dsqr-server-vm-x86_64" ;;
    dojo)
      echo "hostname 'dojo' no longer has an active flake target" >&2
      exit 1
      ;;
  esac

  case "$target" in
    devbox-macbook-pro-m1|dsqr-mini-001|dsqr-mini-002) kind="darwin" ;;
    *) kind="nixos" ;;
  esac

  printf 'target=%s\nkind=%s\n' "$target" "$kind"

switch target='':
  #!/usr/bin/env bash
  set -euo pipefail

  target="${1:-${NIXNAME:-}}"
  os="$(uname -s)"

  if [[ -z "$target" ]]; then
    if [[ "$os" == "Darwin" ]]; then
      local_name="$(scutil --get LocalHostName 2>/dev/null || true)"
      case "$local_name" in
        dsqr-mini-001|dsqr-mini-002) target="$local_name" ;;
        Davids-MacBook-Pro) target="devbox-macbook-pro-m1" ;;
        *) target="devbox-macbook-pro-m1" ;;
      esac
    else
      target="$(hostname -s 2>/dev/null || hostname)"
    fi
  fi

  case "$target" in
    github-runner) target="github-runner-vm-x86_64" ;;
    gateway) target="gateway-vm-x86_64" ;;
    server) target="dsqr-server-vm-x86_64" ;;
    dojo)
      echo "hostname 'dojo' no longer has an active flake target" >&2
      exit 1
      ;;
  esac

  case "$target" in
    devbox-macbook-pro-m1|dsqr-mini-001|dsqr-mini-002)
      echo "switching darwin config: $target"
      if command -v darwin-rebuild >/dev/null 2>&1; then
        darwin-rebuild switch --flake ".#$target"
      else
        nix run nix-darwin -- switch --flake ".#$target"
      fi
      ;;
    *)
      echo "switching nixos config: $target"
      sudo nixos-rebuild switch --flake ".#$target"
      ;;
  esac

test target='':
  #!/usr/bin/env bash
  set -euo pipefail

  target="${1:-${NIXNAME:-}}"
  os="$(uname -s)"

  if [[ -z "$target" ]]; then
    if [[ "$os" == "Darwin" ]]; then
      local_name="$(scutil --get LocalHostName 2>/dev/null || true)"
      case "$local_name" in
        dsqr-mini-001|dsqr-mini-002) target="$local_name" ;;
        Davids-MacBook-Pro) target="devbox-macbook-pro-m1" ;;
        *) target="devbox-macbook-pro-m1" ;;
      esac
    else
      target="$(hostname -s 2>/dev/null || hostname)"
    fi
  fi

  case "$target" in
    github-runner) target="github-runner-vm-x86_64" ;;
    gateway) target="gateway-vm-x86_64" ;;
    server) target="dsqr-server-vm-x86_64" ;;
    dojo)
      echo "hostname 'dojo' no longer has an active flake target" >&2
      exit 1
      ;;
  esac

  case "$target" in
    devbox-macbook-pro-m1|dsqr-mini-001|dsqr-mini-002)
      echo "building darwin config: $target"
      nix build ".#darwinConfigurations.$target.system"
      ;;
    *)
      echo "building nixos config: $target"
      nix build ".#nixosConfigurations.$target.config.system.build.toplevel"
      ;;
  esac

switch-mini target='':
  #!/usr/bin/env bash
  set -euo pipefail

  target="${1:-${NIXNAME:-$(scutil --get LocalHostName 2>/dev/null || true)}}"

  case "$target" in
    dsqr-mini-001|dsqr-mini-002) ;;
    *)
      echo "switch-mini expects dsqr-mini-001 or dsqr-mini-002; got: ${target:-<empty>}" >&2
      exit 1
      ;;
  esac

  echo "switching mini config: $target"
  if command -v darwin-rebuild >/dev/null 2>&1; then
    darwin-rebuild switch --flake ".#$target"
  else
    nix run nix-darwin -- switch --flake ".#$target"
  fi

check:
  nix flake check

format:
  nix fmt

clean:
  #!/usr/bin/env bash
  set -euo pipefail
  nix-collect-garbage -d
  nix store optimise
