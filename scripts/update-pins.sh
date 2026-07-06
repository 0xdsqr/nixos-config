#!/usr/bin/env bash
# Bump the pinned versions/hashes of the agent packages in packages/*/package.nix.
#
#   scripts/update-pins.sh [claude-code|codex|codexbar|all]
#
# Each updater is independent; `all` keeps going if one fails and exits non-zero
# only if at least one failed.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

log() { printf '>> %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  return 1
}

# Read the first `key = "value"` string from a nix file.
nix_field() {
  awk -v key="$2" '
    $0 ~ ("^[[:space:]]*" key " = \"") {
      match($0, /"[^"]*"/); print substr($0, RSTART + 1, RLENGTH - 2); exit
    }' "$1"
}

# Replace the first `key = "..."` string in a nix file.
replace_field() {
  local file=$1 key=$2 val=$3 tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v val="$val" '
    !done && $0 ~ ("^[[:space:]]*" key " = \"") { sub(/"[^"]*"/, "\"" val "\""); done = 1 }
    { print }
  ' "$file" >"$tmp" && mv "$tmp" "$file"
}

# Pull `got: sha256-...` out of a nix fixed-output hash-mismatch error.
parse_got() { sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' | head -1; }

gh_api() {
  if command -v gh >/dev/null 2>&1; then
    gh api "$1"
  else
    curl -fsSL ${GH_TOKEN:+-H "Authorization: Bearer ${GH_TOKEN}"} "https://api.github.com/$1"
  fi
}

# Hash a fetchzip source on any platform (matches the darwin-only package output).
fetchzip_hash() {
  nix build --impure --no-link 2>&1 --expr "
    (import (builtins.getFlake \"$ROOT\").inputs.nixpkgs { system = builtins.currentSystem; }).fetchzip {
      url = \"$1\"; hash = \"$FAKE_HASH\"; stripRoot = false;
    }" | parse_got
}

update_claude_code() {
  local file="$ROOT/packages/claude-code/package.nix"
  local base="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
  local latest current plat hash
  latest="$(curl -fsSL "$base/latest")" || die "claude-code: could not fetch latest channel" || return 1
  current="$(nix_field "$file" version)"
  if [[ "$latest" == "$current" ]]; then
    log "claude-code up to date ($current)"
    return 0
  fi
  log "claude-code $current -> $latest"
  for plat in darwin-arm64 darwin-x64 linux-arm64 linux-x64; do
    hash="$(nix store prefetch-file --json "$base/$latest/$plat/claude" | jq -r .hash)" || die "claude-code: prefetch $plat failed" || return 1
    replace_field "$file" "$plat" "$hash"
  done
  replace_field "$file" version "$latest"
}

update_codex() {
  local file="$ROOT/packages/codex/package.nix"
  local latest current srchash cargohash
  latest="$(gh_api "repos/openai/codex/releases?per_page=30" |
    jq -r '.[].tag_name' | grep -E '^rust-v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^rust-v//' | sort -V | tail -1)" ||
    die "codex: could not list releases" || return 1
  [[ -n "$latest" ]] || die "codex: no stable rust-v* release found" || return 1
  current="$(nix_field "$file" version)"
  if [[ "$latest" == "$current" ]]; then
    log "codex up to date ($current)"
    return 0
  fi
  log "codex $current -> $latest"
  # Derive src + cargo-vendor hashes from the real fetchers via fake-hash builds.
  replace_field "$file" version "$latest"
  replace_field "$file" hash "$FAKE_HASH"
  replace_field "$file" cargoHash "$FAKE_HASH"
  srchash="$(nix build "$ROOT#codex" --no-link 2>&1 | parse_got)"
  [[ -n "$srchash" ]] || die "codex: could not determine src hash" || return 1
  replace_field "$file" hash "$srchash"
  cargohash="$(nix build "$ROOT#codex" --no-link 2>&1 | parse_got)"
  [[ -n "$cargohash" ]] || die "codex: could not determine cargoHash" || return 1
  replace_field "$file" cargoHash "$cargohash"
}

update_codexbar() {
  local file="$ROOT/packages/codexbar/package.nix"
  local latest current url hash
  latest="$(gh_api repos/steipete/CodexBar/releases/latest | jq -r .tag_name)" || die "codexbar: could not fetch latest" || return 1
  latest="${latest#v}"
  current="$(nix_field "$file" version)"
  if [[ "$latest" == "$current" ]]; then
    log "codexbar up to date ($current)"
    return 0
  fi
  log "codexbar $current -> $latest"
  url="https://github.com/steipete/CodexBar/releases/download/v${latest}/CodexBar-macos-universal-${latest}.zip"
  hash="$(fetchzip_hash "$url")"
  [[ -n "$hash" ]] || die "codexbar: could not determine src hash" || return 1
  replace_field "$file" version "$latest"
  replace_field "$file" hash "$hash"
}

main() {
  case "${1:-all}" in
    claude-code) update_claude_code ;;
    codex) update_codex ;;
    codexbar) update_codexbar ;;
    all)
      local rc=0 pkg
      for pkg in update_claude_code update_codex update_codexbar; do
        "$pkg" || rc=1
      done
      return "$rc"
      ;;
    *)
      printf 'usage: %s [claude-code|codex|codexbar|all]\n' "$0" >&2
      return 1
      ;;
  esac
}

main "$@"
