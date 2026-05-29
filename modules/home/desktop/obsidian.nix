{
  flake.homeModules.obsidian =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrsToList
        optionalAttrs
        recursiveUpdate
        ;
      inherit (lib.lists) unique;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings)
        concatStringsSep
        escapeShellArg
        hasPrefix
        hasSuffix
        removePrefix
        ;
      inherit (lib.types)
        anything
        attrsOf
        bool
        enum
        lines
        listOf
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.home.desktop.obsidian;
      jsonFormat = pkgs.formats.json { };

      defaultCorePlugins = [
        "file-explorer"
        "global-search"
        "switcher"
        "graph"
        "backlink"
        "canvas"
        "outgoing-link"
        "tag-pane"
        "page-preview"
        "daily-notes"
        "templates"
        "note-composer"
        "command-palette"
        "slash-command"
        "editor-status"
        "bookmarks"
        "properties"
        "word-count"
      ];

      defaultAppSettings = {
        alwaysUpdateLinks = true;
        attachmentFolderPath = "assets";
        newFileFolderPath = "Inbox";
        newFileLocation = "folder";
        readableLineLength = true;
        showInlineTitle = true;
        showLineNumber = true;
        showUnsupportedFiles = true;
        spellcheck = true;
        useMarkdownLinks = true;
      };

      defaultAppearance = {
        baseFontSize = 16;
        enabledCssSnippets = [ "dsqr-readable" ];
        interfaceFontFamily = "";
        textFontFamily = "";
      };

      defaultReadableSnippet = ''
        body {
          --file-line-width: 760px;
          --font-text-size: 16px;
          --line-height-normal: 1.65;
        }

        .markdown-preview-view p,
        .markdown-source-view.mod-cm6 .cm-line {
          line-height: 1.65;
        }

        .callout,
        .markdown-preview-view img {
          border-radius: 8px;
        }
      '';

      normalizePath =
        path:
        if hasPrefix "~/" path then
          "${config.home.homeDirectory}/${removePrefix "~/" path}"
        else if hasPrefix "/" path then
          path
        else
          "${config.home.homeDirectory}/${path}";

      profileDefaultPaths = {
        personal = "Documents/Obsidian/Personal";
        stablecore = "Documents/Obsidian/Stablecore";
        work = "Documents/Obsidian/Work";
      };

      profilePath =
        if cfg.profilePath != null then
          cfg.profilePath
        else if cfg.profile != null then
          profileDefaultPaths.${cfg.profile}
        else
          null;

      mkProfileVault = path: {
        inherit path;

        appSettings = { };
        appearance = { };
        communityPlugins = [ ];
        corePlugins = null;
        enable = true;
        extraFiles = { };
        folders = [ ];
        force = false;
        hotkeys = { };
        snippets = { };
      };

      profileVaults = optionalAttrs (cfg.profile != null) { ${cfg.profile} = mkProfileVault profilePath; };

      snippetFileName = name: if hasSuffix ".css" name then name else "${name}.css";

      vaultType = submodule (
        { name, ... }:
        {
          options = {
            enable = mkEnableOption "this Obsidian vault" // {
              default = true;
            };

            path = mkOption {
              type = str;
              default = "Documents/Obsidian/${name}";
              description = "Vault path. Relative paths are resolved under home.homeDirectory.";
            };

            force = mkOption {
              type = bool;
              default = false;
              description = "Overwrite managed Obsidian config files during activation.";
            };

            folders = mkOption {
              type = listOf str;
              default = [ ];
              description = "Vault folders to ensure exist.";
            };

            appSettings = mkOption {
              type = attrsOf anything;
              default = { };
              description = "Per-vault app.json settings merged over shared defaults.";
            };

            appearance = mkOption {
              type = attrsOf anything;
              default = { };
              description = "Per-vault appearance.json settings merged over shared defaults.";
            };

            corePlugins = mkOption {
              type = nullOr (listOf str);
              default = null;
              description = "Core plugin ids for core-plugins.json. Null uses shared defaults.";
            };

            communityPlugins = mkOption {
              type = listOf str;
              default = [ ];
              description = "Community plugin ids to enable once installed in the vault.";
            };

            hotkeys = mkOption {
              type = attrsOf anything;
              default = { };
              description = "Per-vault hotkeys.json settings merged over shared defaults.";
            };

            snippets = mkOption {
              type = attrsOf lines;
              default = { };
              description = "CSS snippets written under .obsidian/snippets.";
            };

            extraFiles = mkOption {
              type = attrsOf lines;
              default = { };
              description = "Extra files written relative to the vault .obsidian directory.";
            };
          };
        }
      );

      mkJson = name: value: jsonFormat.generate "obsidian-${name}.json" value;

      mkInstallFile = force: target: source: ''
        install_obsidian_file ${escapeShellArg (toString source)} ${escapeShellArg target} ${if force then "force" else "seed"}
      '';

      mkEnsureDir = directory: ''
        $DRY_RUN_CMD mkdir -p ${escapeShellArg directory}
      '';

      mkVaultScript =
        name: vault:
        let
          vaultPath = normalizePath vault.path;
          obsidianPath = "${vaultPath}/.obsidian";
          folders = [
            vaultPath
            obsidianPath
            "${obsidianPath}/snippets"
          ]
          ++ map (folder: "${vaultPath}/${folder}") (cfg.defaults.folders ++ vault.folders);

          appSettings = recursiveUpdate cfg.defaults.appSettings vault.appSettings;
          appearance = recursiveUpdate cfg.defaults.appearance vault.appearance;
          corePlugins = if vault.corePlugins == null then cfg.defaults.corePlugins else vault.corePlugins;
          communityPlugins = unique (cfg.defaults.communityPlugins ++ vault.communityPlugins);
          hotkeys = recursiveUpdate cfg.defaults.hotkeys vault.hotkeys;
          snippets = cfg.defaults.snippets // vault.snippets;
          extraFiles = cfg.defaults.extraFiles // vault.extraFiles;
        in
        concatStringsSep "\n" (
          map mkEnsureDir folders
          ++ [
            (mkInstallFile vault.force "${obsidianPath}/app.json" (mkJson "${name}-app" appSettings))
            (mkInstallFile vault.force "${obsidianPath}/appearance.json" (mkJson "${name}-appearance" appearance))
            (mkInstallFile vault.force "${obsidianPath}/core-plugins.json" (mkJson "${name}-core-plugins" corePlugins))
            (mkInstallFile vault.force "${obsidianPath}/community-plugins.json" (
              mkJson "${name}-community-plugins" communityPlugins
            ))
            (mkInstallFile vault.force "${obsidianPath}/hotkeys.json" (mkJson "${name}-hotkeys" hotkeys))
          ]
          ++ mapAttrsToList (
            snippetName: text:
            mkInstallFile vault.force "${obsidianPath}/snippets/${snippetFileName snippetName}" (
              pkgs.writeText "obsidian-${name}-${snippetFileName snippetName}" text
            )
          ) snippets
          ++ mapAttrsToList (
            relativePath: text:
            mkInstallFile vault.force "${obsidianPath}/${relativePath}" (
              pkgs.writeText "obsidian-${name}-${builtins.baseNameOf relativePath}" text
            )
          ) extraFiles
        );

      effectiveVaults = recursiveUpdate profileVaults cfg.vaults;
      enabledVaults = filterAttrs (_: vault: vault.enable) effectiveVaults;
      vaultScripts = concatStringsSep "\n" (mapAttrsToList mkVaultScript enabledVaults);
    in
    {
      options.dsqr.home.desktop.obsidian = {
        enable = mkEnableOption "Obsidian vault bootstrap configuration";

        profile = mkOption {
          type = nullOr (enum [
            "personal"
            "stablecore"
            "work"
          ]);
          default = null;
          description = "Optional single-vault profile for hosts that should not mix personal and work vaults.";
        };

        profilePath = mkOption {
          type = nullOr str;
          default = null;
          description = "Optional path override for the selected profile vault.";
        };

        defaults = {
          folders = mkOption {
            type = listOf str;
            default = [
              "Inbox"
              "Daily"
              "Templates"
              "assets"
            ];
            description = "Folders created in every managed vault.";
          };

          appSettings = mkOption {
            type = attrsOf anything;
            default = defaultAppSettings;
            description = "Shared app.json settings.";
          };

          appearance = mkOption {
            type = attrsOf anything;
            default = defaultAppearance;
            description = "Shared appearance.json settings.";
          };

          corePlugins = mkOption {
            type = listOf str;
            default = defaultCorePlugins;
            description = "Shared core plugin ids.";
          };

          communityPlugins = mkOption {
            type = listOf str;
            default = [ ];
            description = "Shared community plugin ids to enable once installed.";
          };

          hotkeys = mkOption {
            type = attrsOf anything;
            default = { };
            description = "Shared hotkeys.json settings.";
          };

          snippets = mkOption {
            type = attrsOf lines;
            default."dsqr-readable.css" = defaultReadableSnippet;
            description = "Shared CSS snippets written under .obsidian/snippets.";
          };

          extraFiles = mkOption {
            type = attrsOf lines;
            default = { };
            description = "Shared extra files written relative to .obsidian.";
          };
        };

        vaults = mkOption {
          type = attrsOf vaultType;
          default = { };
          description = "Obsidian vaults to create and seed.";
        };
      };

      config = mkIf (cfg.enable && enabledVaults != { }) {
        home.activation.obsidianVaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install_obsidian_file() {
            src="$1"
            target="$2"
            mode="$3"

            $DRY_RUN_CMD mkdir -p "$(dirname "$target")"

            if [ "$mode" = "force" ] || [ ! -e "$target" ]; then
              $DRY_RUN_CMD install -m 0644 "$src" "$target"
            else
              echo "Keeping existing Obsidian file: $target" >&2
            fi
          }

          ${vaultScripts}
        '';
      };
    };
}
