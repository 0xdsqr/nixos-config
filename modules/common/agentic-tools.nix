{ inputs, ... }:
{
  flake.commonModules.agentic-tools-package = _: {
    nixpkgs.overlays = [
      (final: _: { agentic-tools = final.callPackage ../../packages/agentic-tools { pi-skills-src = inputs.pi-skills; }; })
    ];
  };
}
