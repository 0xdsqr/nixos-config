{ self, inputs, ... }:
{
  flake.commonModules."home-manager" =
    {
      config,
      hostMeta,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        attrByPath
        mkIf
        mkMerge
        mkOption
        types
        ;
      nixLib = inputs.nixpkgs.lib // inputs.darwin.lib;
      keys = import ./../keys.nix;
      specialArgs = { inherit self inputs; };
      hostProfiles = [
        "darwin-laptop-aarch64"
        "darwin-mini-aarch64"
        "linux-desktop-aarch64"
        "linux-desktop-x86_64"
        "linux-vm-aarch64"
        "linux-vm-x86_64"
      ];
      hostProfile =
        if hostMeta.profile != null then
          hostMeta.profile
        else if hostMeta.class == "darwin" then
          "darwin-laptop-aarch64"
        else
          "linux-vm-x86_64";
      defaultHomeProfile =
        if
          builtins.elem hostProfile [
            "darwin-mini-aarch64"
            "linux-vm-aarch64"
            "linux-vm-x86_64"
          ]
        then
          "server"
        else
          "desktop";
      homeCfg = attrByPath [ "dsqr" "home" ] {
        profile = "desktop";
        imports = [ ];
      } config;
      nixosUserEnabled = attrByPath [ "dsqr" "nixos" "user" "passwordAgeFile" ] null config != null;
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
    {
      options.dsqr = {
        host.profile = mkOption {
          type = types.enum hostProfiles;
          default = hostProfile;
          description = "High-level host shape used to derive sane defaults for this machine.";
        };

        home = {
          profile = mkOption {
            type = types.enum [
              "desktop"
              "server"
            ];
            default = defaultHomeProfile;
            description = "Shared Home Manager profile to apply for this host.";
          };

          imports = mkOption {
            type = types.listOf types.deferredModule;
            default = [ ];
            description = "Additional Home Manager modules merged into the primary user profile for this host.";
          };
        };
      };

      options.home.extraModules = mkOption {
        type = types.listOf types.deferredModule;
        default = nixLib.attrValues self.homeModules;
        description = "Home Manager shared modules enabled for this host.";
      };

      config = mkMerge [
        {
          home-manager.backupFileExtension = "pre-home-manager";
          home-manager.sharedModules =
            [
              sharedContextModule
              sharedHomeDefaultsModule
            ]
            ++ config.home.extraModules;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        (mkIf pkgs.stdenv.isDarwin {
          home-manager.users.${config.system.primaryUser}.imports = homeCfg.imports;
        })

        (mkIf (pkgs.stdenv.isLinux && nixosUserEnabled) {
          home-manager.users.dsqr.imports = homeCfg.imports;
        })
      ];
    };
}
