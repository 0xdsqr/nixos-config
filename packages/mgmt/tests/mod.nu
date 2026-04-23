use assert.nu [equal truthy]

const SCRIPT_DIR = (path self | path dirname)
const DEFAULT_MOD = ($SCRIPT_DIR | path join ".." "mod.nu" | path expand)

export def "test module exports public commands" [] {
  let mgmt_mod = ($env.MGMT_MOD? | default $DEFAULT_MOD)
  truthy ($mgmt_mod | is-not-empty) "MGMT_MOD is not set"

  let result = do {
    nu --no-config-file -c $'use ($mgmt_mod) *; scope commands | where name in ["help" "version"] | get name | to json'
  } | complete

  equal $result.exit_code 0 $"stderr: ($result.stderr | str trim)"

  let names = $result.stdout | from json
  truthy ($names | any {|name| $name == "help" }) "module should export help"
  truthy ($names | any {|name| $name == "version" }) "module should export version"
}
