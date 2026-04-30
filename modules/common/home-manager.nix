{ self, inputs, ... }:
{
  flake.commonModules."home-manager" =
    { lib, pkgs, ... }:
    let
      inherit (lib.modules) mkForce;

      keys = import ./keys.nix;
      homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/dsqr" else "/home/dsqr";

      specialArgs = {
        inherit self inputs;
        inherit (inputs) agenix exo;
      };

      sharedKeysModule = {
        _module.args = { inherit keys; };
      };

      sharedHomeDefaultsModule =
        { lib, ... }:
        let
          inherit (lib.modules) mkDefault;
        in
        {
          home.stateVersion = mkDefault "25.11";
        };
    in
    {
      home-manager.users.dsqr.home = {
        homeDirectory = mkForce homeDirectory;
        username = "dsqr";
      };

      home-manager.backupFileExtension = "pre-home-manager";
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.sharedModules = [
        sharedKeysModule
        sharedHomeDefaultsModule
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
}
