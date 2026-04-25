{
  flake.homeModules.aws =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      awsConfig = lib.generators.toINI { } {
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
      home.packages = [ pkgs.awscli2 ];
      home.sessionVariables.AWS_PAGER = "";

      xdg.configFile."aws/config".text = awsConfig;

      home.activation.ensureAwsCredentials = lib.hm.dag.entryAfter [ "ensureXdgToolingPaths" ] ''
        if [ ! -e "${config.xdg.configHome}/aws/credentials" ]; then
          touch "${config.xdg.configHome}/aws/credentials"
        fi
      '';
    };
}
