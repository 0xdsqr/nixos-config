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
      enabledThemes = filterAttrs (name: _: cfg.themes.${name}.enable) (import ../../packages/pi/themes);
      themeFiles = mapAttrs' (
        name: _: nameValuePair "pi/agent/themes/${name}.json" { source = "${cfg.package}/share/pi/themes/${name}.json"; }
      ) enabledThemes;
    in
    {
      options.programs.pi = import ../../packages/pi/options.nix { inherit lib pkgs; };

      config = mkIf cfg.enable {
        home.packages = singleton cfg.package;
        home.sessionVariables.PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent";

        xdg.configFile = themeFiles;
      };
    };
}
