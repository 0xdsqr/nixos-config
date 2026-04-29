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
      inherit (lib.types) lines package;

      cfg = config.dsqr.home.aws;

      defaultConfig = toINI { } {
        "profile dsqr-dave" = {
          sso_session = "dsqr";
          sso_account_id = "244826541288";
          sso_role_name = "AdministratorAccess";
          region = "us-east-1";
          output = "json";
        };

        "sso-session dsqr" = {
          sso_start_url = "https://d-90660ae665.awsapps.com/start";
          sso_region = "us-east-1";
          sso_registration_scopes = "sso:account:access";
        };
      };
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

        config.extraText = mkOption {
          type = lines;
          default = "";
          description = "Additional AWS config text appended after the managed default config.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.AWS_PAGER = "";

        xdg.configFile."aws/config" = mkIf cfg.config.enable {
          text = defaultConfig + optionalString (cfg.config.extraText != "") ("\n" + cfg.config.extraText);
        };

        home.activation.ensureAwsCredentials = lib.hm.dag.entryAfter (singleton "ensureXdgToolingPaths") /* bash */ ''
          if [ ! -e "${config.xdg.configHome}/aws/credentials" ]; then
            touch "${config.xdg.configHome}/aws/credentials"
          fi
        '';
      };
    };
}
