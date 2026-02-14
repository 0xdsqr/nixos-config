{
  nixpkgs,
  inputs,
  overlays,
}:
name:
{
  system,
  user,
  machineConfig ? ../machines/${name}.nix,
  userOSConfig ? ../users/${user}/${if darwin then "darwin" else "nixos"}.nix,
  homeManagerConfig ? ../users/${user}/home-manager.nix,
  extraModules ? [ ],
  extraPackages ? [ ],
  darwin ? false,
  wsl ? false,
  homeManager ? true,
}:
let
  isWSL = wsl;
  isLinux = !darwin && !isWSL;
  userHMConfig = homeManagerConfig;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

in
systemFunc {
  inherit system;
  specialArgs = {
    inherit inputs isLinux isWSL;
    currentSystemName = name;
    currentSystemUser = user;
  };
  modules = [
    { nixpkgs.overlays = overlays; }
    (if isWSL && builtins.hasAttr "nixos-wsl" inputs then inputs."nixos-wsl".nixosModules.wsl else { })
    machineConfig
    userOSConfig
  ]
  ++ (
    if homeManager then
      [
        home-manager.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user} = import userHMConfig {
            isWSL = isWSL;
            inputs = inputs;
          };
        }
      ]
    else
      [ ]
  )
  ++ [
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
