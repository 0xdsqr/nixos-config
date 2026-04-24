{
  flake.darwinModules.exo =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      inherit (config.dsqr.darwin) exo;

      exoPackage = inputs.exo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.dsqr.darwin = {
        devbox.enable = mkEnableOption "Devbox-specific Darwin settings";
        exo.enable = mkEnableOption "Exo-specific Darwin settings";
      };

      config = mkIf exo.enable {
        environment.systemPackages = [
          exoPackage
          pkgs.uv
        ];

        system.activationScripts.miniClusterPower.text = ''
          /usr/bin/pmset -a sleep 0 \
            displaysleep 0 \
            disksleep 0 \
            standby 0 \
            autopoweroff 0 \
            womp 1 \
            tcpkeepalive 1 \
            autorestart 1 \
            powernap 1
        '';
      };
    };
}
