{ self, inputs, ... }:
{
  flake.commonModules."home-manager" =
    _:
    let
      keys = import ./../keys.nix;

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
      home-manager.users.dsqr = { };

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
