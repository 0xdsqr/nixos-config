use logger.nu [command-line info section success]

const RAW_VERSION = "@version@"
const VERSION = if ($RAW_VERSION | str starts-with "@") { "dev" } else { $RAW_VERSION }

# Print CLI usage.
export def help [] {
  success $"mgmt v($VERSION)"
  info "Local CLI for this nixos-config workspace."
  print ""

  section "Usage"
  print "  mgmt <command> [args]"
  print ""

  section "Commands"
  command-line "help" "Show this help screen"
  command-line "version" "Print the current CLI version"
  print ""

  section "Examples"
  print "  mgmt help"
  print "  mgmt version"
}

# Print the current CLI version.
export def version [] {
  print $VERSION
}

# Print CLI usage as the default command entrypoint.
export def main [] {
  help
}
