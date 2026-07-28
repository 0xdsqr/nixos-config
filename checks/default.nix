{
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib.attrsets)
    attrNames
    filterAttrs
    hasAttr
    mapAttrs
    mapAttrsToList
    ;
  inherit (lib.lists) filter sort;
  inherit (lib.lists) concatLists optional unique;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix;

  observabilityContract = import ../profiles/ops/observability/contract.nix;

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
      "pup"
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

  observabilityHostNames = sortedNames observabilityContract.hosts;
  definedHostNames = sortedNames self.hostDefinitions;
  missingObservabilityHosts = filter (name: !hasAttr name observabilityContract.hosts) definedHostNames;
  duplicateRoutingLabels =
    builtins.length observabilityContract.identity.lowCardinalityRoutingLabels
    != builtins.length (unique observabilityContract.identity.lowCardinalityRoutingLabels);
  duplicateForbiddenFields =
    builtins.length observabilityContract.privacy.forbiddenFields
    != builtins.length (unique observabilityContract.privacy.forbiddenFields);
  supportedCollectors = [
    "darwin-alloy"
    "disabled"
    "kubernetes-gitops"
    "nixos-alloy"
  ];
  hostsWithUnsupportedCollectors = filter (
    name: !(builtins.elem observabilityContract.hosts.${name}.collector supportedCollectors)
  ) observabilityHostNames;
  kubernetesHostsWithWrongOwner = filter (
    name: hasPrefix "srv-lx-k8s-" name && observabilityContract.hosts.${name}.collector != "kubernetes-gitops"
  ) observabilityHostNames;
  disabledHosts = filter (name: !observabilityContract.hosts.${name}.baseline) observabilityHostNames;
  expectedDisabledHosts = [
    "dev-mbp-personal"
    "dev-mbp-stablecore"
  ];
  expectedRetentionDays = {
    logs = 14;
    metrics = 30;
    profiles = 14;
    traces = 14;
  };
  observabilityErrors = concatLists [
    (optional (
      missingObservabilityHosts != [ ]
    ) "missing host coverage: ${concatStringsSep ", " missingObservabilityHosts}")
    (optional duplicateRoutingLabels "low-cardinality routing labels must be unique")
    (optional duplicateForbiddenFields "forbidden privacy fields must be unique")
    (optional (
      hostsWithUnsupportedCollectors != [ ]
    ) "unsupported collectors on: ${concatStringsSep ", " hostsWithUnsupportedCollectors}")
    (optional (
      kubernetesHostsWithWrongOwner != [ ]
    ) "Kubernetes collector ownership must remain with GitOps: ${concatStringsSep ", " kubernetesHostsWithWrongOwner}")
    (optional (disabledHosts != expectedDisabledHosts) "only the two MacBook workstations may omit the host baseline")
    (optional (
      observabilityContract.retentionDays != expectedRetentionDays
    ) "observability retention does not match the accepted 30/14/14/14-day contract")
  ];
  observabilitySummary =
    if observabilityErrors == [ ] then
      {
        inherit (observabilityContract)
          backends
          budgets
          ownership
          retentionDays
          schemaVersion
          ;
        hosts = observabilityHostNames;
      }
    else
      builtins.throw "invalid observability contract: ${concatStringsSep "; " observabilityErrors}";

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
      mkNeovimHome =
        extraModule:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            self.homeModules.neovim
            {
              home.username = "neovim-smoke";
              home.homeDirectory = "/tmp/neovim-smoke";
              home.stateVersion = "25.11";
            }
            extraModule
          ];
        };

      neovimHome = mkNeovimHome { };
      neovimConfig = neovimHome.config.programs.neovim;
      neovimInit = pkgs.writeText "neovim-smoke-init.lua" neovimConfig.initLua;
      neovimPack = neovimHome.config.xdg.dataFile."nvim/site/pack/hm".source;
      neovimSmoke = ./neovim-smoke.lua;

      telescopeDisabledHome = mkNeovimHome { dsqr.home.neovim.plugins.telescope.enable = false; };
      telescopeDisabledPluginNames = builtins.map (
        entry: (entry.plugin or entry).pname
      ) telescopeDisabledHome.config.programs.neovim.plugins;
      unexpectedTelescopePlugins = filter (hasInfix "telescope") telescopeDisabledPluginNames;
      neovimToggleSummary =
        if unexpectedTelescopePlugins == [ ] then
          telescopeDisabledPluginNames
        else
          builtins.throw "Disabling telescope left plugin(s) enabled: ${concatStringsSep ", " unexpectedTelescopePlugins}";

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

        observability-contract =
          pkgs.runCommandLocal "nixos-config-observability-contract-${system}" { summary = builtins.toJSON observabilitySummary; }
            ''
              mkdir -p "$out"
              printf '%s\n' "$summary" > "$out/contract.json"
            '';

        neovim-smoke =
          pkgs.runCommandLocal "nixos-config-neovim-smoke-${system}" { toggleSummary = builtins.toJSON neovimToggleSummary; }
            ''
              export HOME="$TMPDIR/home"
              export NVIM_SMOKE_REPO=${self}
              export XDG_CACHE_HOME="$TMPDIR/cache"
              export XDG_CONFIG_HOME="$TMPDIR/config"
              export XDG_DATA_HOME="$TMPDIR/data"
              export XDG_RUNTIME_DIR="$TMPDIR/runtime"
              export XDG_STATE_HOME="$TMPDIR/state"

              mkdir -p \
                "$HOME" \
                "$XDG_CACHE_HOME" \
                "$XDG_CONFIG_HOME" \
                "$XDG_DATA_HOME/nvim/site/pack" \
                "$XDG_RUNTIME_DIR" \
                "$XDG_STATE_HOME"
              ln -s ${neovimPack} "$XDG_DATA_HOME/nvim/site/pack/hm"

              ${neovimConfig.finalPackage}/bin/nvim --headless -u ${neovimInit} -l ${neovimSmoke}

              mkdir -p "$out"
              ${neovimConfig.finalPackage}/bin/nvim --version > "$out/version.txt"
              printf '%s\n' "$toggleSummary" > "$out/telescope-disabled-plugins.json"
            '';
      };
    };
}
