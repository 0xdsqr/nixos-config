def assert-equal [label: string actual: any expected: any] {
  if $actual != $expected {
    error make {
      msg: $"($label): expected ($expected | to nuon), got ($actual | to nuon)"
    }
  }
}

assert-equal "session variable" $env.NU_SMOKE_SESSION_VARIABLE "available"
assert-equal "Nu config variable" $env.NU_SMOKE_CONFIG_VARIABLE "configured"
assert-equal "XDG_CONFIG_HOME" $env.XDG_CONFIG_HOME "/tmp/nixos-config-nushell-smoke/.config"
assert-equal "XDG_CACHE_HOME" $env.XDG_CACHE_HOME "/tmp/nixos-config-nushell-smoke/.cache"
assert-equal "XDG_DATA_HOME" $env.XDG_DATA_HOME "/tmp/nixos-config-nushell-smoke/.local/share"
assert-equal "XDG_STATE_HOME" $env.XDG_STATE_HOME "/tmp/nixos-config-nushell-smoke/.local/state"
assert-equal "CODEX_HOME" $env.CODEX_HOME "/tmp/nixos-config-nushell-smoke/.config/codex"
assert-equal "CLAUDE_CONFIG_DIR" $env.CLAUDE_CONFIG_DIR "/tmp/nixos-config-nushell-smoke/.config/claude-code"

assert-equal "Nu env path" ($nu.env-path | into string) "/tmp/nixos-config-nushell-smoke/.config/nushell/env.nu"
assert-equal "Nu data directory" ($nu.data-dir | into string) "/tmp/nixos-config-nushell-smoke/.local/share/nushell"
assert-equal "Nu cache directory" ($nu.cache-dir | into string) "/tmp/nixos-config-nushell-smoke/.cache/nushell"

let pathEntries = if (($env.PATH | describe) starts-with "list") {
  $env.PATH | each { into string }
} else {
  $env.PATH | split row (char esep)
}

if "/tmp/nixos-config-nushell-smoke/custom-bin" not-in $pathEntries {
  error make { msg: "Home Manager sessionPath is missing from Nushell PATH" }
}

if not ($pathEntries | any { |entry| $entry ends-with "/inherited-bin" }) {
  error make { msg: "Nushell PATH did not preserve its inherited entries" }
}

if (($env.TERMINFO_DIRS? | default "" | to nuon) | str contains '$TERMINFO_DIRS') {
  error make { msg: "TERMINFO_DIRS retained an unexpanded shell expression" }
}
