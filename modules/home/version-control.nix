{
  flake.homeModules.git =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.lists) optionals singleton;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption mkPackageOption;
      inherit (lib.types)
        anything
        attrsOf
        bool
        enum
        nullOr
        path
        str
        ;

      cfg = config.dsqr.home.versionControl;
      tomlFormat = pkgs.formats.toml { };
      hasSshSigningKey = cfg.git.signing.ssh.privateKeyFile != null || cfg.git.signing.ssh.publicKey != null;
      useSshSigning = cfg.git.signing.enable && cfg.git.signing.format == "ssh" && hasSshSigningKey;
      signingKey =
        if cfg.git.signing.format == "ssh" then
          (
            if cfg.git.signing.ssh.privateKeyFile != null then
              toString cfg.git.signing.ssh.privateKeyFile
            else
              "key::${cfg.git.signing.ssh.publicKey}"
          )
        else
          cfg.git.signing.key;
    in
    {
      options.dsqr.home.versionControl = {
        enable = mkEnableOption "version control tooling" // {
          default = true;
        };

        git = {
          package = mkPackageOption pkgs "git" { };

          userName = mkOption {
            type = nullOr str;
            default = null;
            description = "Default Git author name.";
          };

          userEmail = mkOption {
            type = nullOr str;
            default = null;
            description = "Default Git author email.";
          };

          credential.helper = mkOption {
            type = str;
            default = "store";
            description = "Git credential helper.";
          };

          github.user = mkOption {
            type = nullOr str;
            default = null;
            description = "Default GitHub username used by tooling.";
          };

          extraSettings = mkOption {
            type = attrsOf anything;
            default = { };
            description = "Extra Git settings merged into the generated config.";
          };

          configIncludePath = mkOption {
            type = nullOr path;
            default = null;
            description = "Optional Git config include file appended after the generated base config.";
          };

          signing = {
            enable = mkEnableOption "Git signing" // {
              default = false;
            };

            format = mkOption {
              type = enum [
                "openpgp"
                "ssh"
                "x509"
              ];
              default = "openpgp";
              description = "Git signing format.";
            };

            key = mkOption {
              type = nullOr str;
              default = null;
              description = "Signing key identifier or path.";
            };

            signByDefault = mkOption {
              type = bool;
              default = true;
              description = "Whether commits and tags should be signed by default.";
            };

            ssh.publicKey = mkOption {
              type = nullOr str;
              default = null;
              description = "SSH public key used when Git signing format is ssh.";
            };

            ssh.privateKeyFile = mkOption {
              type = nullOr path;
              default = null;
              description = "Path to SSH private key for signing. When set, uses the file directly instead of the agent, which avoids SSH_AUTH_SOCK inheritance issues in signing subprocesses.";
            };
          };
        };

        lazygit.enable = mkEnableOption "lazygit" // {
          default = true;
        };

        gh.enable = mkEnableOption "GitHub CLI integration" // {
          default = true;
        };

        glab.enable = mkEnableOption "GitLab CLI integration" // {
          default = true;
        };

        gpg.enable = mkEnableOption "GPG tooling" // {
          default = true;
        };

        jj = {
          enable = mkEnableOption "Jujutsu" // {
            default = false;
          };

          package = mkPackageOption pkgs "jujutsu" { };

          signing.key = mkOption {
            type = nullOr str;
            default = null;
            description = "SSH public key used for JJ signing.";
          };
        };
      };

      config = mkIf cfg.enable {
        home.packages =
          optionals cfg.lazygit.enable (singleton pkgs.lazygit)
          ++ optionals cfg.glab.enable (singleton pkgs.glab)
          ++ optionals cfg.jj.enable [
            pkgs.jjui
            cfg.jj.package
            pkgs.mergiraf
          ];

        programs.git.enable = true;
        programs.git.package = cfg.git.package;
        programs.git.includes = mkIf (cfg.git.configIncludePath != null) [ { path = cfg.git.configIncludePath; } ];
        programs.git.settings = {
          branch.autosetuprebase = "always";
          color.ui = true;
          core.askPass = "";
          core.editor = "nvim";
          credential.helper = cfg.git.credential.helper;
          init.defaultBranch = "master";
          push.default = "tracking";
        }
        // optionalAttrs (cfg.git.github.user != null) { github.user = cfg.git.github.user; }
        // optionalAttrs (cfg.git.userName != null || cfg.git.userEmail != null) {
          user =
            optionalAttrs (cfg.git.userName != null) { name = cfg.git.userName; }
            // optionalAttrs (cfg.git.userEmail != null) { email = cfg.git.userEmail; };
        }
        // optionalAttrs (useSshSigning && cfg.git.signing.ssh.publicKey != null) {
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        }
        // cfg.git.extraSettings;
        programs.git.signing.format = mkIf cfg.git.signing.enable cfg.git.signing.format;
        programs.git.signing.key = mkIf (cfg.git.signing.enable && (useSshSigning || cfg.git.signing.key != null)) signingKey;
        programs.git.signing.signByDefault = mkIf cfg.git.signing.enable cfg.git.signing.signByDefault;

        programs.gh.enable = mkIf cfg.gh.enable true;
        programs.gh.gitCredentialHelper.enable = mkIf cfg.gh.enable true;

        programs.gpg.enable = mkIf cfg.gpg.enable true;

        services.gpg-agent = mkIf (cfg.gpg.enable && pkgs.stdenv.isLinux) {
          enable = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry-curses;
        };

        xdg.configFile."git/allowed_signers" = mkIf (useSshSigning && cfg.git.signing.ssh.publicKey != null) {
          text = "*@* ${cfg.git.signing.ssh.publicKey}\n";
        };

        xdg.configFile."jj/config.toml" = mkIf cfg.jj.enable {
          source = tomlFormat.generate "jj-config.toml" {
            git.fetch = [
              "origin"
              "upstream"
              "rad"
            ];
            git.push = "origin";
            git.sign-on-push = true;
            signing = {
              backend = "ssh";
              behavior = "drop";
            }
            // optionalAttrs (cfg.jj.signing.key != null) { inherit (cfg.jj.signing) key; };
            ui.conflict-marker-style = "snapshot";
            ui.diff-editor = ":builtin";
            ui.graph.style = "square";
            ui.pager = [
              (getExe pkgs.bash)
              "-c"
              "exec \${PAGER:-less}"
            ];
            user =
              optionalAttrs (cfg.git.userName != null) { name = cfg.git.userName; }
              // optionalAttrs (cfg.git.userEmail != null) { email = cfg.git.userEmail; };
          };
        };
      };
    };
}
