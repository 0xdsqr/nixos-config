{ inputs, config, ... }: {
  flake.commonModules.nixpkgs = _: {
    nixpkgs.overlays =
      builtins.map (name: inputs.${name}.overlays.default) [
        "agenix"
        "darwin"
      ]
      ++ builtins.attrValues config.flake.overlays;
  };
}
