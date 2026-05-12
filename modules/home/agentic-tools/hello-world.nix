{
  flake.homeModules.agentic-tools-hello-world =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) package;

      cfg = config.dsqr.home.agentic-tools.hello-world;
      master = config.dsqr.home.agentic-tools;
    in
    {
      options.dsqr.home.agentic-tools.hello-world = {
        enable = mkEnableOption "hello-world custom agent skill (placeholder)" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = pkgs.agentic-tools.hello-world;
          description = "hello-world custom skill package.";
        };
      };

      config = mkIf (master.enable && cfg.enable) {
        home.file = {
          ".agents/skills/hello-world".source = cfg.package;
          ".claude/skills/hello-world".source = cfg.package;
          ".config/codex/skills/hello-world".source = cfg.package;
        };
      };
    };
}
