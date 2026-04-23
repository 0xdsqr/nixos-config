{
  flake.homeModules.tailscale =
    { lib, pkgs, ... }:
    let
      inherit (lib) getExe mkIf;
      inherit (pkgs.stdenv) hostPlatform;
    in
    {
      programs.nushell.shellAliases.ts = if hostPlatform.isDarwin then "tailscale" else getExe pkgs.tailscale;

      home.packages = mkIf hostPlatform.isLinux [ pkgs.tailscale ];
    };
}
