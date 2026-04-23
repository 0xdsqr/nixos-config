use cli.nu [run]

def main [
  --verbose (-v)
  --dry-run (-n)
  command?: string
  ...args: string
] {
  let context = {
    verbose: $verbose
    dry_run: $dry_run
  }

  run $context $command ...$args
}
