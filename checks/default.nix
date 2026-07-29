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
  inherit (lib.strings) concatStringsSep hasInfix;

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

      nushellSmokeHomeDirectory = "/tmp/nixos-config-nushell-smoke";
      mkNushellHome =
        extraModule:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            self.homeModules.nushell
            self.homeModules.xdg
            {
              home.username = "nushell-smoke";
              home.homeDirectory = nushellSmokeHomeDirectory;
              home.stateVersion = "25.11";
            }
            extraModule
          ];
        };

      nushellHome = mkNushellHome {
        # The workstation package only disables upstream Darwin checks. Use the
        # pinned package directly here so this smoke test stays cache-friendly.
        dsqr.home.nu.package = pkgs.nushell;
        home.sessionVariables = {
          CLAUDE_CONFIG_DIR = "${nushellSmokeHomeDirectory}/.config/claude-code";
          CODEX_HOME = "${nushellSmokeHomeDirectory}/.config/codex";
          NU_SMOKE_SESSION_VARIABLE = "available";
        };
        home.sessionPath = [ "${nushellSmokeHomeDirectory}/custom-bin" ];
        programs.nushell.environmentVariables.NU_SMOKE_CONFIG_VARIABLE = "configured";
      };
      nushellHomeConfig = nushellHome.config;
      nushellConfigPath = "${nushellHomeConfig.programs.nushell.configDir}/config.nu";
      nushellConfig = nushellHomeConfig.home.file.${nushellConfigPath}.source;
      nushellSessionVariables = "${nushellHomeConfig.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
      nushellSmoke = ./nushell-smoke.nu;

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

        nushell-smoke = pkgs.runCommandLocal "nixos-config-nushell-smoke-${system}" { } ''
          export HOME=${lib.escapeShellArg nushellSmokeHomeDirectory}
          export PATH="$TMPDIR/inherited-bin:/usr/bin:/bin"
          export XDG_RUNTIME_DIR="$TMPDIR/runtime"
          unset \
            CLAUDE_CONFIG_DIR \
            CODEX_HOME \
            NU_SMOKE_CONFIG_VARIABLE \
            NU_SMOKE_SESSION_VARIABLE \
            TERMINFO_DIRS \
            XDG_CACHE_HOME \
            XDG_CONFIG_HOME \
            XDG_DATA_HOME \
            XDG_STATE_HOME \
            __HM_SESS_VARS_SOURCED

          mkdir -p \
            "$TMPDIR/inherited-bin" \
            "$XDG_RUNTIME_DIR"

          ${lib.optionalString pkgs.stdenv.isDarwin ''
            # Darwin normally receives these before Nu starts from the zsh
            # bootstrap. Model that boundary without sourcing the script.
            export XDG_CACHE_HOME=${lib.escapeShellArg nushellHomeConfig.xdg.cacheHome}
            export XDG_CONFIG_HOME=${lib.escapeShellArg nushellHomeConfig.xdg.configHome}
            export XDG_DATA_HOME=${lib.escapeShellArg nushellHomeConfig.xdg.dataHome}
            export XDG_STATE_HOME=${lib.escapeShellArg nushellHomeConfig.xdg.stateHome}
          ''}

          ${lib.getExe nushellHomeConfig.programs.nushell.package} \
            --no-history \
            --config ${nushellConfig} \
            ${nushellSmoke}

          mkdir -p "$out"
          ${lib.getExe nushellHomeConfig.programs.nushell.package} --version > "$out/version.txt"
        '';
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        nushell-zsh-bootstrap =
          let
            zshDotDirRelative = lib.removePrefix "${nushellSmokeHomeDirectory}/" nushellHomeConfig.programs.zsh.dotDir;
            zshXdgEnv = nushellHomeConfig.home.file."${zshDotDirRelative}/.zshenv".source;
            zshRcEntry = nushellHomeConfig.home.file."${zshDotDirRelative}/.zshrc";
            zshRc = zshRcEntry.source;
            zshRcText = zshRcEntry.text;
            zshXdgEnvText = nushellHomeConfig.home.file."${zshDotDirRelative}/.zshenv".text;
            bootstrapSummary =
              if
                hasInfix "__DSQR_NU_HANDOFF" zshRcText
                && hasInfix "ZSH_EXECUTION_STRING+x" zshRcText
                && hasInfix "etc/profile.d/hm-session-vars.sh" zshXdgEnvText
              then
                {
                  environment = nushellSessionVariables;
                  handoffMarker = "__DSQR_NU_HANDOFF";
                  commandGuard = "ZSH_EXECUTION_STRING";
                }
              else
                builtins.throw "Darwin Nushell bootstrap must load Home Manager's environment and preserve zsh commands";
          in
          pkgs.runCommandLocal "nixos-config-nushell-zsh-bootstrap-${system}" { summary = builtins.toJSON bootstrapSummary; } ''
            mkdir -p \
              "$TMPDIR/home" \
              "$TMPDIR/inherited-bin" \
              "$TMPDIR/runtime" \
              "$TMPDIR/zsh"

            ln -s ${zshXdgEnv} "$TMPDIR/zsh/.zshenv"
            ln -s ${zshRc} "$TMPDIR/zsh/.zshrc"

            export HOME="$TMPDIR/home"
            export NU_BOOTSTRAP_MARKER="$TMPDIR/zsh-command-ran"
            export PATH="$TMPDIR/inherited-bin:/usr/bin:/bin"
            export SHELL=/bin/zsh
            export XDG_RUNTIME_DIR="$TMPDIR/runtime"
            export ZDOTDIR="$TMPDIR/zsh"
            unset \
              __DSQR_NU_HANDOFF \
              __HM_SESS_VARS_SOURCED \
              __HM_ZSH_SESS_VARS_SOURCED

            ${lib.getExe pkgs.zsh} -d -ic '
              [[ "$NU_SMOKE_SESSION_VARIABLE" == available ]] || exit 91
              [[ "$XDG_CONFIG_HOME" == /tmp/nixos-config-nushell-smoke/.config ]] || exit 92
              [[ "$XDG_DATA_HOME" == /tmp/nixos-config-nushell-smoke/.local/share ]] || exit 93
              [[ ":$PATH:" == *":/tmp/nixos-config-nushell-smoke/custom-bin:"* ]] || exit 94
              [[ "$SHELL" == /bin/zsh ]] || exit 95
              printf command-ran > "$NU_BOOTSTRAP_MARKER"
            '
            test "$(cat "$NU_BOOTSTRAP_MARKER")" = command-ran

            mkdir -p "$out"
            printf '%s\n' "$summary" > "$out/bootstrap.json"
          '';
      };
    };
}
