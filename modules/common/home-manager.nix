{ self, inputs, ... }:
{ lib, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../../keys.nix;
  inputHomeModules = builtins.map (name: inputs.${name}.homeModules.default) [ "sops-nix" ];
  specialArgs = inputs // {
    inherit self inputs keys;
    inherit (self.lib) dtil;
  };
in
{
  home-manager.backupFileExtension = "pre-home-manager";
  home-manager.sharedModules = inputHomeModules ++ nixLib.attrValues self.homeModules;
  home-manager.extraSpecialArgs = specialArgs;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.dsqr.home.stateVersion = lib.mkDefault "25.11";
}
