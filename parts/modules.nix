{ inputs, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
in
{
  flake = {
    lib = nixLib // {
      roost = import ./../packages/roost { lib = nixLib; };
    };
  };
}
