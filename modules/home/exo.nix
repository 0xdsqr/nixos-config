_: {
  flake.homeModules.exo =
    {
      config,
      exo,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) escapeShellArgs;
      inherit (lib.types)
        attrsOf
        listOf
        package
        str
        ;
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      cfg = config.dsqr.home.exo;
      exoPackage = exo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.dsqr.home.exo = {
        enable = mkEnableOption "exo local AI cluster node";

        package = mkOption {
          type = package;
          default = exoPackage;
          description = "exo package to install and run.";
        };

        environmentVariables = mkOption {
          type = attrsOf str;
          default = { };
          example = {
            EXO_LIBP2P_NAMESPACE = "home-cluster";
            EXO_OFFLINE = "true";
          };
          description = ''
            Environment variables for the exo service.
          '';
        };

        logDirectory = mkOption {
          type = str;
          default = "${config.home.homeDirectory}/Library/Logs/exo";
          description = "Directory for exo service logs.";
        };

        logFile = mkOption {
          type = str;
          default = "${cfg.logDirectory}/exo.log";
          description = "Combined stdout and stderr log file for the exo service.";
        };

        extraArgs = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "--no-worker" ];
          description = ''
            Extra command-line arguments passed to `exo`.
          '';
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;

        home.activation.ensureExoLogDirectory = lib.hm.dag.entryAfter (singleton "writeBoundary") /* bash */ ''
          mkdir -p "${cfg.logDirectory}"
          touch "${cfg.logFile}"
        '';

        systemd.user.services.exo = mkIf isLinux {
          Unit = {
            Description = "exo local AI cluster node";
            After = singleton "network.target";
          };

          Service = {
            ExecStart = escapeShellArgs (singleton (getExe cfg.package) ++ cfg.extraArgs);
            Environment = mapAttrsToList (name: value: "${name}=${value}") cfg.environmentVariables;
            Restart = "on-failure";
          };

          Install.WantedBy = singleton "default.target";
        };

        launchd.agents.exo = mkIf isDarwin {
          enable = true;
          config = {
            ProgramArguments = singleton (getExe cfg.package) ++ cfg.extraArgs;
            EnvironmentVariables = cfg.environmentVariables;
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
            StandardErrorPath = cfg.logFile;
            StandardOutPath = cfg.logFile;
          };
        };
      };
    };
}
