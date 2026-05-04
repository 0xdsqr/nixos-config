{
  flake.homeModules.aws =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.generators) toINI;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) optionalString;
      inherit (lib.types)
        attrsOf
        bool
        int
        lines
        oneOf
        package
        str
        ;

      cfg = config.dsqr.home.aws;
    in
    {
      options.dsqr.home.aws = {
        enable = mkEnableOption "AWS CLI tooling" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.awscli2;
          description = "AWS CLI package to install.";
        };

        config.enable = mkEnableOption "managed AWS config file";

        config.sections = mkOption {
          type = attrsOf (
            attrsOf (oneOf [
              bool
              int
              str
            ])
          );
          default = { };
          description = "AWS config sections rendered to INI with toINI.";
        };

        config.text = mkOption {
          type = lines;
          default = "";
          description = "Additional raw AWS config text appended after rendered config sections.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.AWS_PAGER = "";

        xdg.configFile."aws/config" = mkIf cfg.config.enable {
          text =
            optionalString (cfg.config.sections != { }) (toINI { } cfg.config.sections)
            + optionalString (cfg.config.text != "") ((optionalString (cfg.config.sections != { }) "\n") + cfg.config.text);
        };

        home.activation.ensureAwsCredentials = lib.hm.dag.entryAfter (singleton "ensureXdgToolingPaths") /* bash */ ''
          if [ ! -e "${config.xdg.configHome}/aws/credentials" ]; then
            touch "${config.xdg.configHome}/aws/credentials"
          fi
        '';
      };
    };
}
