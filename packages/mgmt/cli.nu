use logger.nu [
  blank
  brand
  command-line
  debug
  error
  flag-line
  info
  section
]

const RAW_VERSION = "@version@"
const VERSION = if ($RAW_VERSION | str starts-with "@") { "dev" } else { $RAW_VERSION }
const COMMANDS = [
  {
    name: "help"
    summary: "Show this help screen"
    examples: [ "mgmt help" ]
  }
  {
    name: "version"
    summary: "Print the current CLI version"
    examples: [ "mgmt version" ]
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

# Print CLI usage.
export def help [context?: record] {
  let ctx = (normalize-context $context)

  brand $"mgmt v($VERSION)"
  info "Local CLI for this nixos-config workspace."
  if $ctx.dry_run {
    info "dry-run mode is enabled"
  }
  blank

  section "Usage"
  print "  mgmt [--verbose] [--dry-run] <command> [args]"
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
  debug $ctx "printing mgmt version"
  print $VERSION
}

export def run [context?: record, command?: string, ...args: string] {
  let ctx = (normalize-context $context)
  let selected = ($command | default "help")

  debug $ctx $"dispatching command: ($selected)"

  match $selected {
    "help" => { help $ctx }
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
export def "mgmt main" [context?: record] {
  main $context
}
