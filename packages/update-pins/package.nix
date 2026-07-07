{
  writeShellApplication,
  nushell,
  nix-prefetch-github,
}:
writeShellApplication {
  name = "update-pins";
  runtimeInputs = [
    nushell
    nix-prefetch-github
  ];
  text = ''
    exec nu ${./update-pins.nu} "$@"
  '';
}
