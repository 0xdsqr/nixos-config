{
  flake.darwinModules.shells =
    { config, pkgs, ... }:
    let
      inherit (pkgs) bashInteractive zsh;
    in
    {
      programs.zsh.enable = true;

      environment.shells = [
        bashInteractive
        zsh
      ];

      users.users.${config.system.primaryUser}.shell = zsh;
    };
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
