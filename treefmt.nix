_: {
  projectRootFile = "flake.nix";

  # Nix formatting
  programs.nixfmt.enable = true;
  programs.deadnix.enable = true;
  programs.statix.enable = true;
}
