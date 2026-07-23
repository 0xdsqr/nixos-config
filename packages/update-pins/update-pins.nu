# Bump the pinned versions/hashes of the agent packages.
#   update-pins [claude-code|codex|codexbar|pi|all]

const FAKE = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

def repo-root [] { ^git rev-parse --show-toplevel | str trim }

def gh-json [path: string] {
  let token = ($env.GH_TOKEN? | default "")
  if ($token | is-empty) {
    http get $"https://api.github.com/($path)"
  } else {
    http get --headers { Authorization: $"Bearer ($token)" } $"https://api.github.com/($path)"
  }
}

# First `key = "value"` string in a nix file.
def nix-field [file: string, key: string] {
  open --raw $file
  | lines
  | where {|ln| ($ln | str trim) | str starts-with $"($key) = \""}
  | get 0
  | parse --regex '"(?<v>[^"]*)"'
  | get v.0
}

# Replace the first `key = "..."` string in a nix file.
def replace-field [file: string, key: string, val: string] {
  let ls = (open --raw $file | lines)
  let idx = ($ls | enumerate | where {|r| ($r.item | str trim) | str starts-with $"($key) = \""} | get index.0)
  let newline = ($ls | get $idx | str replace --regex '"[^"]*"' $"\"($val)\"")
  $"($ls | update $idx $newline | str join "\n")\n" | save --force --raw $file
}

# Pull `got: sha256-...` out of a nix fixed-output hash-mismatch error.
def parse-got [text: string] {
  $text
  | lines
  | where {|ln| $ln =~ 'got:'}
  | get 0
  | parse --regex 'got:\s*(?<h>sha256-[A-Za-z0-9+/=]*)'
  | get h.0
}

# fetchFromGitHub hash via nix-prefetch-github (on PATH via the package wrapper).
def gh-prefetch [owner: string, repo: string, rev: string] {
  ^nix-prefetch-github --rev $rev $owner $repo | from json | get hash
}

# Build an attr with a fake hash in place and recover the real one from the error.
def build-got [attr: string] {
  let res = (do { ^nix build $"(repo-root)#($attr)" --no-link } | complete)
  parse-got ($res.stdout + $res.stderr)
}

# Hash a fetchzip source on any platform (matches the darwin-only package output).
def fetchzip-hash [url: string] {
  let root = (repo-root)
  let expr = $"let pkgs = import \(builtins.getFlake \"($root)\"\).inputs.nixpkgs {}; in pkgs.fetchzip { url = \"($url)\"; hash = \"($FAKE)\"; stripRoot = false; }"
  let res = (do { ^nix build --impure --no-link --expr $expr } | complete)
  parse-got $res.stderr
}

def update-claude-code [] {
  let file = $"(repo-root)/packages/claude-code/package.nix"
  let base = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
  let latest = (http get $"($base)/latest" | into string | str trim)
  let current = (nix-field $file "version")
  if $latest == $current {
    print $"claude-code up to date \(($current)\)"
    return
  }
  print $"claude-code ($current) -> ($latest)"
  for plat in [darwin-arm64 darwin-x64 linux-arm64 linux-x64] {
    let h = (^nix store prefetch-file --json $"($base)/($latest)/($plat)/claude" | from json | get hash)
    replace-field $file $plat $h
  }
  replace-field $file "version" $latest
}

def update-codex [] {
  let file = $"(repo-root)/packages/codex/cli.nix"
  let latest = (
    gh-json "repos/openai/codex/releases?per_page=30"
    | get tag_name
    | where {|t| $t =~ '^rust-v[0-9]+\.[0-9]+\.[0-9]+$'}
    | each {|t| $t | str replace 'rust-v' ''}
    | sort --natural
    | last
  )
  let current = (nix-field $file "version")
  if $latest == $current {
    print $"codex up to date \(($current)\)"
    return
  }
  print $"codex ($current) -> ($latest)"
  let root = (repo-root)
  replace-field $file "version" $latest
  replace-field $file "hash" $FAKE
  replace-field $file "cargoHash" $FAKE
  let src = (do { ^nix build $"($root)#codex" --no-link } | complete)
  replace-field $file "hash" (parse-got $src.stderr)
  let cargo = (do { ^nix build $"($root)#codex" --no-link } | complete)
  replace-field $file "cargoHash" (parse-got $cargo.stderr)
}

def update-codexbar [] {
  let file = $"(repo-root)/packages/codex/bar.nix"
  let latest = (gh-json "repos/steipete/CodexBar/releases/latest" | get tag_name | str replace --regex '^v' '')
  let current = (nix-field $file "version")
  if $latest == $current {
    print $"codexbar up to date \(($current)\)"
    return
  }
  print $"codexbar ($current) -> ($latest)"
  let url = $"https://github.com/steipete/CodexBar/releases/download/v($latest)/CodexBar-macos-universal-($latest).zip"
  replace-field $file "version" $latest
  replace-field $file "hash" (fetchzip-hash $url)
}

def update-pi [] {
  let pkg = $"(repo-root)/packages/pi/package.nix"

  let tag = (gh-json "repos/earendil-works/pi/releases/latest" | get tag_name)
  let version = ($tag | str replace --regex '^v' '')
  let cur = (nix-field $pkg "version")
  if $version == $cur {
    print $"pi-coding-agent up to date \(($cur)\)"
  } else {
    print $"pi-coding-agent ($cur) -> ($version)"
    replace-field $pkg "version" $version
    replace-field $pkg "hash" (gh-prefetch "earendil-works" "pi" $tag)
    let model_data_url = $"https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-($version).tgz"
    let model_data_hash = (^nix store prefetch-file --json $model_data_url | from json | get hash)
    replace-field $pkg "modelDataHash" $model_data_hash
    replace-field $pkg "npmDepsHash" $FAKE
    replace-field $pkg "npmDepsHash" (build-got "pi")
  }
}

def main [pkg: string = "all"] {
  match $pkg {
    "claude-code" => { update-claude-code }
    "codex" => { update-codex }
    "codexbar" => { update-codexbar }
    "pi" => { update-pi }
    "all" => {
      try { update-claude-code } catch {|e| print $"!! claude-code failed: ($e.msg)"}
      try { update-codex } catch {|e| print $"!! codex failed: ($e.msg)"}
      try { update-codexbar } catch {|e| print $"!! codexbar failed: ($e.msg)"}
      try { update-pi } catch {|e| print $"!! pi failed: ($e.msg)"}
    }
    _ => {
      print "usage: update-pins [claude-code|codex|codexbar|pi|all]"
      exit 1
    }
  }
}
