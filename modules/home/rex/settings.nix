{
  flake.homeModules.rex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrsToList;
      inherit (lib.modules) mkDefault mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings)
        concatStringsSep
        escapeShellArg
        escapeShellArgs
        isString
        ;
      inherit (lib.trivial) boolToString;
      inherit (lib.types)
        attrsOf
        bool
        float
        int
        listOf
        nullOr
        oneOf
        path
        str
        ;

      cfg = config.dsqr.home.rex;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

      defaultsWrite = key: "run /usr/bin/defaults write ${escapeShellArg cfg.settingsDomain} ${escapeShellArg key}";

      typedValue =
        value:
        if builtins.isBool value then
          "-bool ${boolToString value}"
        else if builtins.isInt value then
          "-int ${toString value}"
        else if builtins.isFloat value then
          "-float ${toString value}"
        else if isString value then
          "-string ${escapeShellArg value}"
        else
          "-array ${escapeShellArgs value}";

      settings = filterAttrs (_: value: value != null) cfg.settings;

      script = concatStringsSep "\n" (
        mapAttrsToList (key: value: "${defaultsWrite key} ${typedValue value}") settings
        ++ mapAttrsToList (
          key: file: ''${defaultsWrite key} -data "$(/usr/bin/xxd -p ${file} | /usr/bin/tr -d '\n')"''
        ) cfg.dataSettings
      );
    in
    {
      options.dsqr.home.rex = {
        settingsDomain = mkOption {
          type = str;
          default = "com.superlogical.rex";
          description = "macOS preferences domain of the Rex app.";
        };

        settings = mkOption {
          type = attrsOf (
            nullOr (oneOf [
              bool
              int
              float
              str
              (listOf str)
            ])
          );
          default = { };
          example = {
            "Workspace.terminalFontPointSize" = 18;
            "Workspace.tabStyle" = "vertical";
          };
          description = ''
            Rex for Mac settings, written one key at a time to the app's
            preferences. Keys not listed here stay under the app's control.
            Null leaves a key alone. Restart Rex to pick up a change.
          '';
        };

        dataSettings = mkOption {
          type = attrsOf path;
          default = { };
          description = "Settings the app stores as raw data. Each file's bytes are written to its key.";
        };

        serve = {
          enable = mkEnableOption "serving this Mac's Rex over its built-in Tailscale";

          hostName = mkOption {
            type = nullOr str;
            default = null;
            description = "Preferred name for this Mac's Rex node on the tailnet.";
          };

          allowTailnetMembers = mkOption {
            type = bool;
            default = false;
            description = "Let other tailnet members connect, instead of only the account that signed in.";
          };
        };
      };

      config = mkIf (cfg.enable && isDarwin) (mkMerge [
        { home.activation.rexSettings = mkIf (script != "") (lib.hm.dag.entryAfter [ "writeBoundary" ] script); }

        # Which tailnet the node joins is decided by the sign-in inside Rex, so
        # only the serving switches live here.
        (mkIf cfg.serve.enable {
          dsqr.home.rex.settings = {
            "rex.server.tailnet-enabled" = mkDefault true;
            "rex.server.tailnet-hostname" = mkDefault cfg.serve.hostName;
            "rex.server.tailnet-allow-tailnet-members" = mkDefault cfg.serve.allowTailnetMembers;
          };
        })
      ]);
    };
}
