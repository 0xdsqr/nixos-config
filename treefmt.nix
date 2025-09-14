{ pkgs, ... }: {
  # treefmt configuration
  projectRootFile = "flake.nix";

  # Enable nixfmt for all .nix files
  programs.nixfmt.enable = true;

  # (Optional) add other formatters later, like prettier/black/etc.
}
