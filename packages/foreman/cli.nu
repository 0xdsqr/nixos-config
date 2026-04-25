use logger.nu [
  blank
  brand
  command-line
  debug
  error
  flag-line
  info
  section
  success
]

const RAW_VERSION = "@version@"
const VERSION = if ($RAW_VERSION | str starts-with "@") { "dev" } else { $RAW_VERSION }
const DEFAULT_AGENIX_IDENTITY = "~/.ssh/dsqr_homelab_ed25519"
const COMMANDS = [
  {
    name: "help"
    summary: "Show this help screen"
    examples: [ "foreman help" ]
  }
  {
    name: "version"
    summary: "Print the current CLI version"
    examples: [ "foreman version" ]
  }
  {
    name: "secrets"
    summary: "Manage repo secrets"
    examples: [ "foreman secrets sync" ]
  }
]
const GLOBAL_FLAGS = [
  {
    name: "--verbose, -v"
    summary: "Show extra diagnostic output"
  }
  {
    name: "--dry-run, -n"
    summary: "Preview actions without changing state"
  }
]

def normalize-context [context?: record] {
  let base = ($context | default {})

  {
    verbose: ($base.verbose? | default false)
    dry_run: ($base.dry_run? | default false)
  }
}

def agenix-identity-path [] {
  $DEFAULT_AGENIX_IDENTITY | path expand
}

def secrets-help [] {
  section "Secrets Commands"
  command-line "sync" "Rekey all age secrets with the homelab SSH identity"
  blank
  section "Secrets Examples"
  print "  foreman secrets sync"
}

# Print CLI usage.
export def help [context?: record] {
  let ctx = (normalize-context $context)

  brand $"foreman v($VERSION)"
  info "Local CLI for this nixos-config workspace."
  if $ctx.dry_run {
    info "dry-run mode is enabled"
  }
  blank

  section "Usage"
  print "  foreman [--verbose] [--dry-run] <command> [args]"
  blank

  section "Commands"
  for command in $COMMANDS {
    command-line $command.name $command.summary
  }
  blank

  section "Global Flags"
  for flag in $GLOBAL_FLAGS {
    flag-line $flag.name $flag.summary
  }
  blank

  section "Examples"
  for command in $COMMANDS {
    for example in $command.examples {
      print $"  ($example)"
    }
  }
}

# Print the current CLI version.
export def version [context?: record] {
  let ctx = (normalize-context $context)
  debug $ctx "printing foreman version"
  print $VERSION
}

def run-secrets [context: record, action?: string] {
  let ctx = (normalize-context $context)
  let selected = ($action | default "help")

  debug $ctx $"dispatching secrets command: ($selected)"

  match $selected {
    "help" => { secrets-help }
    "sync" => {
      let identity = agenix-identity-path

      if not ($identity | path exists) {
        error $"missing agenix identity: ($identity)"
        if not $nu.is-interactive { exit 2 }
        return
      }

      let command = $"agenix -i ($identity) -r"
      debug $ctx $"running secrets sync with identity: ($identity)"

      if $ctx.dry_run {
        info $"dry-run: would run `($command)`"
        return
      }

      ^agenix -i $identity -r
      success "Secrets rekey complete."
    }
    _ => {
      error $"unknown secrets command: ($selected)"
      blank
      secrets-help
      if not $nu.is-interactive { exit 2 }
    }
  }
}

export def run [context?: record, command?: string, ...args: string] {
  let ctx = (normalize-context $context)
  let selected = ($command | default "help")

  debug $ctx $"dispatching command: ($selected)"

  match $selected {
    "help" => { help $ctx }
    "secrets" => {
      let action = if (($args | length) > 0) { $args | first } else { null }
      run-secrets $ctx $action
    }
    "version" => { version $ctx }
    _ => {
      error $"unknown command: ($selected)"
      blank
      help $ctx
      if not $nu.is-interactive { exit 2 }
    }
  }
}

# Print CLI usage as the default command entrypoint.
export def main [context?: record] {
  help $context
}

# Print CLI usage as a normal (non-special) command.
export def "foreman main" [context?: record] {
  main $context
}
