{ inputs, ... }: {
  flake.homeModules.rex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        either
        lines
        nullOr
        package
        path
        ;

      cfg = config.dsqr.home.rex;
    in
    {
      imports = [ inputs.rex.homeManagerModules.default ];

      options.dsqr.home.rex = {
        enable = mkEnableOption "Rex CLI tooling and configuration";

        package = mkOption {
          type = package;
          default = inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.rex;
          defaultText = lib.literalExpression "inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.rex";
          description = "Rex package to install.";
        };

        config = mkOption {
          type = nullOr (either lines path);
          default = null;
          description = "Rex Lua configuration written to the XDG config directory at rex/init.lua.";
        };

        sshGuard = mkEnableOption "the Rex SSH terminal compatibility guard" // {
          default = true;
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = !cfg.sshGuard || config.dsqr.home.ssh.enable;
            message = "dsqr.home.rex.sshGuard requires dsqr.home.ssh.enable = true.";
          }
        ];

        programs.rex = {
          enable = true;
          inherit (cfg) package config;

          # modules/home/ssh.nix owns ~/.ssh/config, so include the guard there
          # instead of enabling home-manager's programs.ssh module.
          sshGuard = false;
        };

        dsqr.home.ssh.includes = mkIf cfg.sshGuard [ "${cfg.package}/share/rex/ssh_config.d/50-rex.conf" ];
      };
    };
}
