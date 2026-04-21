{ inputs, ... }:
{
  nixpkgs.overlays = builtins.map (name: inputs.${name}.overlays.default) [
    "agenix"
    "darwin"
    "neovim-nightly-overlay"
    "nix-openclaw"
    "sops-nix"
  ];
}
