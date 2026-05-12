{ inputs, ... }:
{
  flake.commonModules.nix-pi = _: {
    nixpkgs.overlays = [ inputs.nix-pi.overlays.default ];
    home-manager.sharedModules = [ inputs.nix-pi.homeModules.default ];
  };
}
