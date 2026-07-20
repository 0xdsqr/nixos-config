{ self, inputs, ... }: {
  flake.commonModules."home-manager" =
    _:
    let
      specialArgs = {
        inherit self inputs;
        inherit (inputs) agenix;
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
      home-manager.backupFileExtension = "pre-home-manager";
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.sharedModules = [ sharedHomeDefaultsModule ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };
}
