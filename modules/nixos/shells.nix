{
  flake.nixosModules.shells =
    { pkgs, ... }:
    let
      inherit (pkgs) bashInteractive nushell zsh;
    in
    {
      users.defaultUserShell = nushell;

      environment.shells = [
        bashInteractive
        nushell
        zsh
      ];
    };
}
