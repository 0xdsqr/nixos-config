# OpenCode - AI coding agent for the terminal
# Uses upstream flake from github:sst/opencode
inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.eevee.opencode;
  opencodePkg = inputs.opencode.packages.${pkgs.system}.default;
in
{
  options.eevee.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ opencodePkg ];
  };
}
