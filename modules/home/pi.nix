{
  flake.homeModules.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) filterAttrs mapAttrs' nameValuePair;
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkIf;

      cfg = config.programs.pi;
      agentDirectory = "${config.xdg.configHome}/pi/agent";
      enabledExtensions = filterAttrs (name: _: cfg.extensions.${name}.enable) (import ../../packages/agents/pi/extensions);
      configurableExtensions = filterAttrs (_: definition: definition ? settingsFile) enabledExtensions;
      enabledThemes = filterAttrs (name: _: cfg.themes.${name}.enable) (import ../../packages/agents/pi/themes);
      extensionFiles = mapAttrs' (
        name: _: nameValuePair "pi/agent/extensions/${name}" { source = "${cfg.package}/share/pi/extensions/${name}"; }
      ) enabledExtensions;
      extensionSettingsFiles = mapAttrs' (
        name: definition:
        nameValuePair "pi/agent/${definition.settingsFile}" { text = builtins.toJSON cfg.extensions.${name}.settings; }
      ) configurableExtensions;
      modelsFile = lib.optionalAttrs (cfg.models != { }) { "pi/agent/models.json".text = builtins.toJSON cfg.models; };
      themeFiles = mapAttrs' (
        name: _: nameValuePair "pi/agent/themes/${name}.json" { source = "${cfg.package}/share/pi/themes/${name}.json"; }
      ) enabledThemes;
    in
    {
      options.programs.pi = import ../../packages/agents/pi/options.nix { inherit lib pkgs; };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.PI_CODING_AGENT_DIR = agentDirectory;
        programs.nushell.environmentVariables.PI_CODING_AGENT_DIR = agentDirectory;

        xdg.configFile = extensionFiles // extensionSettingsFiles // modelsFile // themeFiles;
      };
    };
}
