{
  flake.homeModules.tailscale =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe mkIf;
    in
    {
      programs.nushell.shellAliases.ts =
        if osConfig.nixpkgs.hostPlatform.isDarwin then "tailscale" else getExe pkgs.tailscale;

      home.packages = mkIf osConfig.nixpkgs.hostPlatform.isLinux [ pkgs.tailscale ];
    };
}
