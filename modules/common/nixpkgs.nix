{ inputs, config, ... }:
{
  flake.commonModules.nixpkgs = _: {
    nixpkgs.overlays =
      builtins.map (name: inputs.${name}.overlays.default) [
        "agenix"
        "darwin"
        "neovim-nightly-overlay"
      ]
      ++ builtins.attrValues config.flake.overlays;
  };
}
