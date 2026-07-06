{
  lib,
  writeShellScriptBin,
  nushell,
}:
writeShellScriptBin "update-pins" ''
  exec ${lib.getExe nushell} ${./update-pins.nu} "$@"
''
