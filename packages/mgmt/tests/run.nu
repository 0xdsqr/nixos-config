#!/usr/bin/env nu

def main [
  --filter: string = "" # Only run tests matching this substring
] {
  const dir = path self | path dirname
  let modules = (
    glob ($dir | path join "*.nu")
    | where {|file| ($file | path basename) != "run.nu" }
    | sort
    | each {|file|
      {
        name: ($file | path basename | str replace ".nu" "")
        path: $file
      }
    }
  )

  mut total = 0
  mut passed = 0
  mut failed = 0
  mut failures = []

  for mod in $modules {
    let commands = (
      nu --no-config-file -c $'use ($mod.path) *; scope commands | where name =~ "^test " | get name | to json'
      | from json
    )

    for test_name in $commands {
      if (not ($filter | is-empty)) and (not ($test_name | str contains $filter)) {
        continue
      }

      $total += 1

      let result = do { nu --no-config-file -c $'use ($mod.path) *; ($test_name)' } | complete

      if $result.exit_code == 0 {
        $passed += 1
        print $"(ansi green)✓(ansi reset) ($mod.name): ($test_name)"
      } else {
        $failed += 1
        $failures = ($failures | append {
          module: $mod.name
          test: $test_name
          stderr: ($result.stderr | str trim)
        })
        print $"(ansi red)✗(ansi reset) ($mod.name): ($test_name)"
      }
    }
  }

  print ""
  print $"(ansi white_bold)Results: ($passed)/($total) passed(ansi reset)"

  if $failed > 0 {
    print ""
    print $"(ansi red_bold)Failures:(ansi reset)"
    for failure in $failures {
      print $"  (ansi red)✗(ansi reset) ($failure.module): ($failure.test)"
      print $"    ($failure.stderr)"
    }
    exit 1
  }
}
