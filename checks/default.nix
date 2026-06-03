{ lib, self, ... }:
let
  inherit (lib.attrsets)
    attrNames
    filterAttrs
    hasAttr
    mapAttrs
    mapAttrsToList
    ;
  inherit (lib.lists) filter sort;
  inherit (lib.strings) concatStringsSep;

  requiredExports = {
    commonModules = [
      "home-manager"
      "nix"
      "nixpkgs"
      "unfree"
    ];

    darwinModules = [
      "homebrew"
      "lapdog"
      "obsidian"
      "sudo"
    ];

    homeModules = [
      "git"
      "neovim"
      "obsidian"
      "ssh"
      "xdg"
    ];

    nixosModules = [
      "openssh"
      "restic"
      "tailscale"
    ];
  };

  sortedNames = attrs: sort (left: right: left < right) (attrNames attrs);

  requireKeys =
    surface: attrs: expected:
    let
      missing = filter (name: !hasAttr name attrs) expected;
    in
    if missing == [ ] then
      sortedNames attrs
    else
      builtins.throw "${surface} is missing expected export(s): ${concatStringsSep ", " missing}";

  moduleExportSummary = {
    commonModules = requireKeys "commonModules" self.commonModules requiredExports.commonModules;
    darwinModules = requireKeys "darwinModules" self.darwinModules requiredExports.darwinModules;
    homeModules = requireKeys "homeModules" self.homeModules requiredExports.homeModules;
    nixosModules = requireKeys "nixosModules" self.nixosModules requiredExports.nixosModules;
  };

  checkHostDefinition =
    name: meta:
    let
      validClass = meta.class == "darwin" || meta.class == "nixos";
      validSystem = meta.system == "aarch64-darwin" || meta.system == "aarch64-linux" || meta.system == "x86_64-linux";
      validPath = builtins.pathExists meta.path;
    in
    if !(validClass && validSystem && validPath) then
      builtins.throw "hostDefinitions.${name} has invalid class, system, or path"
    else
      { inherit (meta) class system; };

  hostDefinitionSummary = mapAttrs checkHostDefinition self.hostDefinitions;

  knownHostForSystem = system: name: hasAttr name self.hostDefinitions && self.hostDefinitions.${name}.system == system;

  drvSummary =
    getDrvPath: system: configurations:
    mapAttrsToList (name: hostConfig: builtins.seq (getDrvPath hostConfig) { inherit name; }) (
      filterAttrs (name: _: knownHostForSystem system name) configurations
    );
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      hostEvalSummary = {
        hostDefinitions = hostDefinitionSummary;

        darwinConfigurations = drvSummary (
          hostConfig: hostConfig.config.system.build.toplevel.drvPath
        ) system self.darwinConfigurations;

        nixosConfigurations = drvSummary (
          hostConfig: hostConfig.config.system.build.toplevel.drvPath
        ) system self.nixosConfigurations;
      };
    in
    {
      checks = {
        module-exports =
          pkgs.runCommandLocal "nixos-config-module-exports-${system}" { summary = builtins.toJSON moduleExportSummary; }
            ''
              mkdir -p "$out"
              printf '%s\n' "$summary" > "$out/exports.json"
            '';

        host-eval = pkgs.runCommandLocal "nixos-config-host-eval-${system}" { summary = builtins.toJSON hostEvalSummary; } ''
          mkdir -p "$out"
          printf '%s\n' "$summary" > "$out/hosts.json"
        '';
      };
    };
}
