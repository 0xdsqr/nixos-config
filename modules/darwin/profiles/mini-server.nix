{
  flake.darwinModules."profiles-mini-server" =
    {
      config,
      hostName,
      lib,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption;

      cfg = config.dsqr.darwin.profiles.miniServer;
    in
    {
      options.dsqr.darwin.profiles.miniServer = {
        enable = mkEnableOption "Mac mini server profile";

        desktop.enable = mkEnableOption "headless-ish desktop defaults for Mac mini servers" // {
          default = true;
        };

        exo.enable = mkEnableOption "Exo service for Mac mini servers" // {
          default = true;
        };

        monitoring.enable = mkEnableOption "Grafana Alloy log shipping for Mac mini servers" // {
          default = true;
        };

        power.enable = mkEnableOption "always-on power defaults for Mac mini servers" // {
          default = true;
        };
      };

      config = mkIf cfg.enable {
        dsqr.darwin = {
          determinate.enable = true;

          desktop = mkIf cfg.desktop.enable {
            dock.enable = false;
            maccy.enable = false;
            system.enable = false;
          };

          grafana = mkIf cfg.monitoring.enable {
            alloy.enable = true;
            loki = {
              enable = true;
              exo.enable = cfg.exo.enable;
            };
          };
        };

        home-manager.users.dsqr =
          { lib, ... }:
          {
            home.activation.ensureExoLogDirectory = mkIf cfg.exo.enable (
              lib.hm.dag.entryAfter [ "writeBoundary" ] /* bash */ ''
                mkdir -p "$HOME/Library/Logs/exo"
                touch "$HOME/Library/Logs/exo/exo.log"
              ''
            );

            launchd.agents.exo.config = mkIf cfg.exo.enable {
              StandardErrorPath = "/Users/dsqr/Library/Logs/exo/exo.log";
              StandardOutPath = "/Users/dsqr/Library/Logs/exo/exo.log";
            };

            services.exo.enable = cfg.exo.enable;

            dsqr.home = {
              aws.enable = false;
              ollama.enable = false;
              neovim.plugins.enable = false;
              nu.integrations.enable = false;
            };
          };

        networking = {
          inherit hostName;
          computerName = hostName;
          localHostName = hostName;
        };

        system.activationScripts.miniClusterPower.text = mkIf cfg.power.enable /* bash */ ''
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
