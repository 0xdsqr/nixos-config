{ inputs, self, ... }:
let
  nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
  keys = import ./../keys.nix;

  homeModuleInputNames = [ "sops-nix" ];

  overlayInputNames = [
    "agenix"
    "darwin"
    "neovim-nightly-overlay"
    "nix-openclaw"
    "sops-nix"
  ];

  inputHomeModules = builtins.map (name: inputs.${name}.homeModules.default) homeModuleInputNames;
  inputOverlays = builtins.map (name: inputs.${name}.overlays.default) overlayInputNames;

  specialArgs = inputs // {
    inherit inputs keys;
  };
in
{
  flake.commonModules = {
    sharedNixpkgs = {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = inputOverlays;
    };

    sharedHomeManager = {
      home-manager.backupFileExtension = "pre-home-manager";
      home-manager.sharedModules = inputHomeModules ++ nixLib.attrValues self.homeModules;
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.dsqr.home.stateVersion = nixLib.mkDefault "25.11";
    };
  };
}
