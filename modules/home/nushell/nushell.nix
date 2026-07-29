{
  flake.homeModules.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets)
        attrByPath
        filterAttrs
        mapAttrs
        optionalAttrs
        recursiveUpdate
        ;
      inherit (lib.hm.nushell) mkNushellInline toNushell;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkDefault mkIf mkOrder;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) escapeShellArg optionalString readFile;
      inherit (lib.types)
        anything
        attrsOf
        lines
        nullOr
        package
        str
        ;
      cfg = config.dsqr.home.nu;
      themeColors = attrByPath [ "dsqr" "theme" "colors" ] {
        magentaBright = "light_magenta";
        red = "red";
      } config;
      defaultPackage =
        if pkgs.stdenv.isDarwin then
          pkgs.nushell.overrideAttrs (_: {
            doCheck = false;
          })
        else
          pkgs.nushell;
      nuExecutable = getExe cfg.package;
      portableSessionVariables = builtins.removeAttrs (filterAttrs (_: value: value != null) config.home.sessionVariables) [
        "TERMINFO_DIRS"
      ];
      inheritedPath = mkNushellInline /* nu */ ''
        (
          ${toNushell { } config.home.sessionPath}
          | append (
              if (($env.PATH? | default [] | describe) starts-with "list") {
                $env.PATH? | default []
              } else {
                $env.PATH? | default "" | split row (char esep)
              }
            )
          | each { into string }
          | uniq
        )
      '';
      terminfoDirs = mkNushellInline /* nu */ ''
        (
          [${toNushell { } "${config.home.profileDirectory}/share/terminfo"}]
          | append ($env.TERMINFO_DIRS? | default "" | split row (char esep))
          | append ${toNushell { } "/usr/share/terminfo"}
          | where { |directory| $directory != "" }
          | uniq
          | str join (char esep)
        )
      '';
      nuSessionVariables =
        mapAttrs (_: mkDefault) portableSessionVariables
        // optionalAttrs (config.home.sessionPath != [ ]) { PATH = mkDefault inheritedPath; }
        // optionalAttrs pkgs.stdenv.isDarwin { TERMINFO_DIRS = mkDefault terminfoDirs; };
    in
    {
      options.dsqr.home.nu = {
        enable = mkEnableOption "Nushell shell configuration" // {
          default = true;
        };

        package = mkOption {
          type = package;
          default = defaultPackage;
          description = "Nushell package to install and configure.";
        };

        integrations.enable = mkEnableOption "Nushell integrations" // {
          default = true;
        };

        settings = mkOption {
          type = attrsOf anything;
          default = { };
          description = "Additional Nushell settings recursively merged into the generated defaults.";
        };

        extraAliases = mkOption {
          type = attrsOf str;
          default = { };
          description = "Extra Nushell aliases merged into the generated defaults.";
        };

        extraConfig = mkOption {
          type = lines;
          default = "";
          description = "Additional Nushell config text appended after the generated defaults.";
        };

        zshPrelude = mkOption {
          type = lines;
          default = "";
          description = "Extra zsh text evaluated before the Darwin zsh-to-Nushell handoff.";
        };

        agenixIdentityFile = mkOption {
          type = nullOr str;
          default = null;
          description = "Optional SSH identity file passed to agenix from the Nushell wrapper.";
        };
      };

      config = mkIf cfg.enable {
        # Zsh exists only to establish the Darwin login environment before Nu.
        # Keep prompt and completion integrations in their owning Nu process.
        home.shell.enableZshIntegration = mkIf pkgs.stdenv.isDarwin false;

        programs.zsh = mkIf pkgs.stdenv.isDarwin {
          enable = true;
          enableCompletion = false;
          dotDir = "${config.xdg.configHome}/zsh";
          initContent = mkOrder 1500 /* zsh */ ''
            ${optionalString (cfg.zshPrelude != "") cfg.zshPrelude}

            # Home Manager loads session variables and session paths before this
            # point. Hand off only a real interactive session so `zsh -c` and
            # `zsh -ic` remain usable, and retain zsh when it is started from Nu.
            if [[ -o interactive \
              && -z "''${ZSH_EXECUTION_STRING+x}" \
              && -z "''${__DSQR_NU_HANDOFF:-}" ]]; then
              export __DSQR_NU_HANDOFF=1
              export SHELL=${escapeShellArg nuExecutable}
              exec ${escapeShellArg nuExecutable}
            fi
          '';
        };

        programs.nushell = {
          enable = true;
          inherit (cfg) package;
          environmentVariables = nuSessionVariables;
          settings = recursiveUpdate {
            show_banner = false;
            edit_mode = "vi";
            cursor_shape = {
              emacs = "line";
              vi_insert = "line";
              vi_normal = "block";
            };
            use_kitty_protocol = true;
            highlight_resolved_externals = true;
            color_config = {
              shape_external = themeColors.red;
              shape_external_resolved = themeColors.magentaBright;
            };
            history = {
              file_format = "sqlite";
              max_size = 100000;
              sync_on_enter = true;
            };
            completions = {
              algorithm = "substring";
              case_sensitive = false;
              quick = true;
              partial = true;
              use_ls_colors = true;
            };
          } cfg.settings;
          shellAliases = {
            v = "nvim";
            vim = "nvim";
            lg = "lazygit";
            ll = "ls -la";
            la = "ls -a";
            sl = "ls";
            tree = "eza --tree --git-ignore --group-directories-first";
          }
          // cfg.extraAliases;
          extraConfig =
            readFile ./nushell.config.nu
            + optionalString (pkgs.stdenv.isDarwin && cfg.agenixIdentityFile != null) /* nu */ ''
              # agenix only auto-discovers ~/.ssh/id_ed25519 and ~/.ssh/id_rsa,
              # so wrap it when a profile supplies a different identity.
              def --wrapped agenix [...args] {
                let key = ($env.HOME | path join ${builtins.toJSON cfg.agenixIdentityFile})
                ^agenix -i $key ...$args
              }
            ''
            + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
        };
      };
    };
}
