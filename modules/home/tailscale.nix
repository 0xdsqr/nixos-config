{
  flake.homeModules.tailscale =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;
      inherit (pkgs.stdenv) hostPlatform;

      cfg = config.dsqr.home.tailscale;
    in
    {
      options.dsqr.home.tailscale = {
        enable = mkEnableOption "Tailscale CLI tooling" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.tailscale;
          description = "Tailscale package to install on Linux hosts.";
        };
      };

      config = mkIf cfg.enable {
        programs.nushell.shellAliases.ts = if hostPlatform.isDarwin then "tailscale" else getExe cfg.package;

        home.packages = mkIf hostPlatform.isLinux (singleton cfg.package);
      };
    };
}
