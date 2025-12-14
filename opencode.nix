inputs:
{
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.opencode.packages.${pkgs.system}.default
  ];
}
