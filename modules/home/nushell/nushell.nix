{
  flake.homeModules.nushell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) recursiveUpdate;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) optionalString readFile;
      inherit (lib.types)
        anything
        attrsOf
        lines
        package
        str
        ;
      cfg = config.dsqr.home.nu;
      defaultPackage =
        if pkgs.stdenv.isDarwin then
          pkgs.nushell.overrideAttrs (_: {
            doCheck = false;
          })
        else
          pkgs.nushell;
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
          description = "Extra zsh text prepended before the Darwin zsh-to-Nushell handoff.";
        };
      };

      config = mkIf cfg.enable {
        home.file.".zshrc" = mkIf pkgs.stdenv.isDarwin {
          text = /* zsh */ ''
            ${optionalString (cfg.zshPrelude != "") cfg.zshPrelude}

            # Ghostty launches zsh on Darwin; immediately hand off to Nushell
            # with the Home Manager-managed config so prompt/theme/integrations load.
            SHELL=${cfg.package}/bin/nu exec ${cfg.package}/bin/nu --config '${config.xdg.configHome}/nushell/config.nu'
          '';
        };

        programs.nushell = {
          enable = true;
          inherit (cfg) package;
          settings = recursiveUpdate {
            show_banner = false;
            edit_mode = "vi";
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
          extraConfig = readFile ./nushell.config.nu
            + optionalString pkgs.stdenv.isDarwin /* nu */ ''
              # agenix only auto-discovers ~/.ssh/id_ed25519 and ~/.ssh/id_rsa,
              # so wrap it to use the homelab key by default on the Mac.
              def --wrapped agenix [...args] {
                let key = ($env.HOME | path join ".ssh" "dsqr_homelab_ed25519")
                ^agenix -i $key ...$args
              }
            ''
            + optionalString (cfg.extraConfig != "") ("\n" + cfg.extraConfig);
        };
      };
    };
}
