{
  flake.darwinModules.tailscale =
    {
      config,
      hostName,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.types)
        enum
        nullOr
        path
        str
        ;

      cfg = config.dsqr.darwin.desktop.tailscale;
      hasAuthKey = cfg.authKeyAgeFile != null && builtins.pathExists cfg.authKeyAgeFile;
      authKeyPath = if hasAuthKey then config.age.secrets.tailscaleAuthKey.path else "/dev/null";

      autoconnect = pkgs.writeShellApplication {
        name = "tailscaled-autoconnect";
        runtimeInputs = [
          cfg.daemon.package
          pkgs.jq
        ];
        text = ''
          for _ in {1..60}; do
            backend_state="$(
              tailscale status --json 2>/dev/null \
                | jq --raw-output '.BackendState // empty' 2>/dev/null \
                || true
            )"

            case "$backend_state" in
              Running)
                exit 0
                ;;
              NeedsLogin|NoState)
                if tailscale up \
                  --auth-key=${lib.escapeShellArg "file:${authKeyPath}"} \
                  --hostname=${lib.escapeShellArg hostName}; then
                  exit 0
                fi
                ;;
              Stopped)
                if tailscale up; then
                  exit 0
                fi
                ;;
            esac

            sleep 2
          done

          echo "tailscaled-autoconnect: timed out waiting for tailscaled" >&2
          exit 1
        '';
      };
    in
    {
      options.dsqr.darwin.desktop.tailscale = {
        enable = mkEnableOption "Tailscale client" // {
          default = true;
        };

        mode = mkOption {
          type = enum [
            "app"
            "daemon"
          ];
          default = "app";
          description = "Whether to run the Tailscale GUI app or the headless launchd daemon.";
        };

        package = mkOption {
          type = str;
          default = "tailscale-app";
          description = "Homebrew cask to install when using app mode.";
        };

        daemon.package = mkPackageOption pkgs "tailscale" { };

        authKeyAgeFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Encrypted age file containing the Tailscale auth key for daemon mode.";
        };
      };

      config = mkIf cfg.enable (mkMerge [
        (mkIf (cfg.mode == "app") { homebrew.casks = singleton cfg.package; })

        (mkIf (cfg.mode == "daemon") {
          age.secrets.tailscaleAuthKey = mkIf hasAuthKey {
            file = cfg.authKeyAgeFile;
            owner = "root";
            mode = "0400";
          };

          services.tailscale = {
            enable = true;
            package = cfg.daemon.package;
          };

          launchd.daemons.tailscaled-autoconnect = mkIf hasAuthKey {
            command = getExe autoconnect;
            serviceConfig = {
              Label = "com.tailscale.tailscaled-autoconnect";
              RunAtLoad = true;
              ProcessType = "Background";
              StandardErrorPath = "/var/log/tailscaled-autoconnect.log";
              StandardOutPath = "/var/log/tailscaled-autoconnect.log";
            };
          };
        })
      ]);
    };
}
