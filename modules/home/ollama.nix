{
  flake.homeModules.ollama =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        attrsOf
        enum
        nullOr
        package
        port
        str
        ;
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      cfg = config.dsqr.home.ollama;
      ollamaPackage = if cfg.acceleration == null then cfg.package else cfg.package.override { inherit (cfg) acceleration; };
    in
    {
      options.dsqr.home.ollama = {
        enable = mkEnableOption "ollama server for local large language models";

        package = mkOption {
          type = package;
          default = pkgs.ollama;
          description = "ollama package to install and run.";
        };

        host = mkOption {
          type = str;
          default = "127.0.0.1";
          description = "Host address for the ollama HTTP interface.";
        };

        port = mkOption {
          type = port;
          default = 11434;
          description = "Port for the ollama HTTP interface.";
        };

        acceleration = mkOption {
          type = nullOr (enum [
            false
            "rocm"
            "cuda"
          ]);
          default = null;
          description = "Acceleration backend override for ollama.";
        };

        environmentVariables = mkOption {
          type = attrsOf str;
          default = { };
          example = {
            OLLAMA_LLM_LIBRARY = "cpu";
          };
          description = ''
            Additional environment variables for the ollama service.
          '';
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton ollamaPackage;

        systemd.user.services.ollama = mkIf isLinux {
          Unit = {
            Description = "Server for local large language models";
            After = singleton "network.target";
          };

          Service = {
            ExecStart = "${getExe ollamaPackage} serve";
            Environment = (lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environmentVariables) ++ [
              "OLLAMA_HOST=${cfg.host}:${toString cfg.port}"
            ];
          };

          Install.WantedBy = singleton "default.target";
        };

        launchd.agents.ollama = mkIf isDarwin {
          enable = true;
          config = {
            ProgramArguments = [
              "${getExe ollamaPackage}"
              "serve"
            ];
            EnvironmentVariables = cfg.environmentVariables // {
              OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
            };
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
          };
        };
      };
    };
}
