{ lib, ... }: {
  perSystem =
    { pkgs, ... }:
    let
      piSkills = pkgs.callPackages ./skills.nix { };
    in
    {
      packages.pi = pkgs.callPackage ./package.nix { };
      packages.pi-skills = pkgs.linkFarm "pi-skills" (lib.mapAttrsToList (name: path: { inherit name path; }) piSkills);
      packages.pi-skill-browser-tools = piSkills.browser-tools;
      packages.pi-skill-brave-search = piSkills.brave-search;
    };

  flake.overlays.pi = final: _: {
    pi-coding-agent = final.callPackage ./package.nix { };
    pi-skills = final.callPackages ./skills.nix { };
  };
}
