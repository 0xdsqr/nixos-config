{
  flake.homeModules.agentic-tools =
    { lib, ... }:
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      options.dsqr.home.agentic-tools = {
        enable = mkEnableOption "Agentic-tools skill set for pi / codex / claude" // {
          default = true;
        };
      };
    };
}
