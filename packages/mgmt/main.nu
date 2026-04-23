const RAW_VERSION = "@version@"
const VERSION = if ($RAW_VERSION | str starts-with "@") { "dev" } else { $RAW_VERSION }

def color [name: string] {
  ansi $name
}

def section [title: string] {
  print $"(color cyan_bold)($title)(color reset)"
}

def command-line [name: string, description: string] {
  print $"  (color green_bold)($name)(color reset) (color light_gray)- ($description)(color reset)"
}

# Local management CLI for this nixos-config repository.
#
# Use this to keep host lifecycle and repo operations in one place.
def main [] {
  main help
}

# Show command help.
def "main help" [] {
  print $"(color green_bold)mgmt(color reset) (color light_gray)v($VERSION)(color reset)"
  print $"(color light_gray)Local CLI for this nixos-config workspace.(color reset)"
  print ""

  section "Usage"
  print "  mgmt <command> [args]"
  print ""

  section "Commands"
  command-line "help" "Show this help screen"
  command-line "reload" "Explain how to refresh the current shell environment"
  command-line "version" "Print the current CLI version"
  command-line "host create <name>" "Stub host scaffolding flow"
  print ""

  section "Examples"
  print "  mgmt help"
  print "  mgmt reload"
  print "  mgmt version"
  print "  mgmt host create media-01"
}

# Print the current CLI version.
def "main version" [] {
  print $VERSION
}

# Explain how to refresh the current shell environment.
#
# A subprocess cannot mutate the parent shell environment, so this command
# points you at the right interactive reload step instead of pretending.
def "main reload" [] {
  print $"(color yellow_bold)interactive step required(color reset)"
  print $"(color light_gray)A standalone CLI cannot update your parent shell environment directly.(color reset)"
  print ""

  section "Run In This Shell"
  print $"  (color green_bold)direnv reload(color reset)"
  print ""

  section "Why"
  print "  direnv works through shell integration, so the reload has to happen in the current interactive shell."
}

# Preview host scaffolding for a new host.
#
# This currently validates the target name and shows the file plan.
# Actual file generation is coming next.
def "main host create" [
  name: string # The new host directory name
] {
  let host_dir = $"hosts/($name)"
  let files = [
    $"($host_dir)/default.nix"
    $"($host_dir)/meta.nix"
    $"($host_dir)/hardware.nix"
  ]

  print $"(color yellow_bold)coming soon(color reset)"
  print $"(color light_gray)Host scaffolding is not wired up yet, but this is the target plan.(color reset)"
  print ""

  section "Host"
  print $"  (color green_bold)($name)(color reset)"
  print ""

  section "Planned Files"
  for file in $files {
    print $"  (color blue_bold)•(color reset) ($file)"
  }
  print $"  (color blue_bold)•(color reset) ($host_dir)/host.password.age"
  print $"    (color light_gray)optional follow-up secret(color reset)"
  print ""

  section "Next Step"
  print "  This command will eventually scaffold the host files and baseline metadata."
}
