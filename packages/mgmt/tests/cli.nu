use assert.nu [equal truthy]

export def "test packaged help exits 0" [] {
  let mgmt_bin = (
    $env.MGMT_BIN?
    | default (which mgmt | get path | first | default "")
  )
  truthy ($mgmt_bin | is-not-empty) "MGMT_BIN is not set"

  let result = do { ^$mgmt_bin help } | complete

  equal $result.exit_code 0 $"stderr: ($result.stderr | str trim)"
  truthy ($result.stdout | str contains "mgmt") "help output should mention mgmt"
  truthy ($result.stdout | str contains "Show this help screen") "help output should describe the help command"
}

export def "test packaged version exits 0" [] {
  let mgmt_bin = (
    $env.MGMT_BIN?
    | default (which mgmt | get path | first | default "")
  )
  truthy ($mgmt_bin | is-not-empty) "MGMT_BIN is not set"

  let result = do { ^$mgmt_bin version } | complete

  equal $result.exit_code 0 $"stderr: ($result.stderr | str trim)"
  truthy ($result.stdout | str trim | str starts-with "0.1.0-") "version output should include the mgmt version prefix"
}
