{
  nixpkgs,
  inputs,
  overlays,
}:
name:
{
  system,
  user,
  extraModules ? [ ],
  extraPackages ? [ ],
  darwin ? false,
  wsl ? false,
  homeManager ? true,
}:
let
  isWSL = wsl;
  isLinux = !darwin && !isWSL;
  machineConfig = ../machines/${name}.nix;
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos"}.nix;
  userHMConfig = ../users/${user}/home-manager.nix;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  homeManagerModule = if darwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;

in
systemFunc {
  inherit system;
  specialArgs = {
    inherit inputs isLinux isWSL;
  };
  modules = [
    { nixpkgs.overlays = overlays; }
    { nixpkgs.config.allowUnfree = true; }
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else { })
    machineConfig
    userOSConfig
    (
      if homeManager then
        homeManagerModule {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user} = import userHMConfig {
            isWSL = isWSL;
            inputs = inputs;
          };
        }
      else
        { }
    )
    {
      environment.systemPackages = extraPackages;
    }
    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        inherit inputs isLinux isWSL;
      };
    }
  ]
  ++ extraModules;
}
