{ self, inputs, ... }:
{
  flake.commonModules."home-manager" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) attrByPath mkIf mkMerge;
      nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
      keys = import ./../keys.nix;
      inputHomeModules = builtins.map (name: inputs.${name}.homeModules.default) [ "sops-nix" ];
      specialArgs = { inherit self inputs; };
      homeCfg = attrByPath [ "dsqr" "home" ] {
        enable = true;
        profile = "desktop";
        userName = "dsqr";
        imports = [ ];
      } config;
      nixosUserEnabled = attrByPath [ "dsqr" "nixos" "user" "enable" ] false config;
      sharedContextModule = {
        _module.args = {
          inherit keys;
          ctx = { inherit keys; };
        };
      };
      sharedHomeDefaultsModule =
        { lib, ... }:
        let
          inherit (lib) mkDefault;
        in
        {
          home.stateVersion = mkDefault "25.11";
        };
    in
    mkMerge [
      {
        home-manager.backupFileExtension = "pre-home-manager";
        home-manager.sharedModules =
          inputHomeModules
          ++ [
            sharedContextModule
            sharedHomeDefaultsModule
          ]
          ++ nixLib.attrValues self.homeModules;
        home-manager.extraSpecialArgs = specialArgs;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }

      (mkIf (pkgs.stdenv.isDarwin && homeCfg.enable) {
        home-manager.users.${config.system.primaryUser}.imports = homeCfg.imports;
      })

      (mkIf (pkgs.stdenv.isLinux && nixosUserEnabled && homeCfg.enable) {
        home-manager.users.${homeCfg.userName}.imports = homeCfg.imports;
      })
    ];
}
