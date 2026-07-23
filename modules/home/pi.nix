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
      enabledExtensions = filterAttrs (name: _: cfg.extensions.${name}.enable) (import ../../packages/pi/extensions);
      enabledThemes = filterAttrs (name: _: cfg.themes.${name}.enable) (import ../../packages/pi/themes);
      extensionFiles = mapAttrs' (
        name: _: nameValuePair "pi/agent/extensions/${name}" { source = "${cfg.package}/share/pi/extensions/${name}"; }
      ) enabledExtensions;
      themeFiles = mapAttrs' (
        name: _: nameValuePair "pi/agent/themes/${name}.json" { source = "${cfg.package}/share/pi/themes/${name}.json"; }
      ) enabledThemes;
    in
    {
      options.programs.pi = import ../../packages/pi/options.nix { inherit lib pkgs; };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.PI_CODING_AGENT_DIR = agentDirectory;
        programs.nushell.environmentVariables.PI_CODING_AGENT_DIR = agentDirectory;

        xdg.configFile = extensionFiles // themeFiles;
      };
    };
}
