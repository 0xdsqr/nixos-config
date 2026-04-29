{
  flake.darwinModules.shells =
    { pkgs, ... }:
    let
      inherit (pkgs) bashInteractive nushell;
    in
    {
      environment.shells = [
        bashInteractive
        nushell
      ];
    };

  flake.nixosModules.shells =
    { pkgs, ... }:
    let
      inherit (pkgs) bashInteractive nushell;
    in
    {
      users.defaultUserShell = nushell;

      environment.shells = [
        bashInteractive
        nushell
      ];
    };
}
