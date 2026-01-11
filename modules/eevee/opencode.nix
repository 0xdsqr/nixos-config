# OpenCode - AI coding agent for the terminal
# Uses the opencode flake from github:anomalyco/opencode
inputs:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  opencodePkg = inputs.opencode.packages.${pkgs.system}.default;
in
{
  home.packages = [
    opencodePkg
  ];
}
