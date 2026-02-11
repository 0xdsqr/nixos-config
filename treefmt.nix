{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  # Nix formatting
  programs.nixfmt.enable = true;
  programs.deadnix.enable = true;
  programs.statix.enable = true;

  # TypeScript/JavaScript formatting
  programs.biome = {
    enable = true;
    settings = {
      formatter = {
        indentStyle = "space";
        indentWidth = 2;
      };
      javascript = {
        formatter = {
          quoteStyle = "double";
          semicolons = "asNeeded";
        };
      };
    };
  };
}
