_inputs:
{
  ...
}:
{
  # This is the module entrypoint. Every file in `imports` becomes part of the
  # same merged NixOS configuration for the host.
  imports = [
    (import ./options.nix)
    (import ./base.nix)
    (import ./packages.nix)
  ];
}
