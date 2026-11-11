# Bump the pinned versions/hashes of agent packages and skill inputs.
#   update-pins [codex|opencode|pi|skills|all]

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

def update-codex [] {
  let file = $"(repo-root)/packages/agents/codex/cli.nix"
  let targets = {
    aarch64-darwin: "aarch64-apple-darwin"
    x86_64-linux: "x86_64-unknown-linux-musl"
    aarch64-linux: "aarch64-unknown-linux-musl"
  }
  # Newest stable release whose prebuilt binaries are already uploaded for every target.
  let assets = ($targets | values | each {|t| $"codex-($t).tar.gz"})
  let latest = (
    gh-json "repos/openai/codex/releases?per_page=30"
    | where {|r| (not $r.prerelease) and ($r.tag_name =~ '^rust-v[0-9]+\.[0-9]+\.[0-9]+$')}
    | where {|r| $assets | all {|a| $a in ($r.assets | get name)}}
    | get tag_name
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
  replace-field $file "version" $latest
  $targets | transpose system target | each {|row|
    let url = $"https://github.com/openai/codex/releases/download/rust-v($latest)/codex-($row.target).tar.gz"
    replace-field $file $row.system (^nix store prefetch-file --json $url | from json | get hash)
  } | ignore
}

def update-pi [] {
  let pkg = $"(repo-root)/packages/agents/pi/package.nix"

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

def update-opencode [] {
  print "updating OpenCode upstream flake"
  ^nix flake update --flake (repo-root) opencode
}

def update-skills [] {
  print "updating agent skill inputs"
  ^nix flake update --flake (repo-root) i-have-adhd
}

def main [pkg: string = "all"] {
  match $pkg {
    "codex" => { update-codex }
    "opencode" => { update-opencode }
    "pi" => { update-pi }
    "skills" => { update-skills }
    "all" => {
      update-codex
      update-opencode
      update-pi
      update-skills
    }
    _ => {
      print "usage: update-pins [codex|opencode|pi|skills|all]"
      exit 1
    }
  }
}
