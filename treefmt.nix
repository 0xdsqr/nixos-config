_: {
  projectRootFile = "flake.nix";

  programs.biome = {
    enable = true;
    includes = [
      "*.ts"
      "*.tsx"
      "*.js"
      "*.jsx"
      "*.json"
    ];
    excludes = [ "**/node_modules/**" ];
    settings = {
      formatter = {
        indentStyle = "space";
        indentWidth = 2;
      };
      javascript.formatter = {
        quoteStyle = "double";
        semicolons = "asNeeded";
      };
      linter.enabled = false;
    };
  };
  programs.nixfmt = {
    enable = true;
    strict = true;
    width = 120;
  };
  programs.deadnix.enable = true;
  programs.statix.enable = true;
}
