{
  flake.homeModules.opencode =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.opencode ];

      xdg.configFile."agents/AGENTS.md".text = ''
        # TODO Custom Agent

        Shared instructions for Dave's coding agents.

        - Preserve the repo's intended folder structure and naming.
        - Prefer declarative Nix and Home Manager changes over ad-hoc local fixes.
        - Keep release notes, changelogs, and migration notes aligned with real code changes.
        - Default to XDG-aware config locations when the tool supports them.
        - Make the smallest correct change first, then tighten style and structure.
        - Prefer explicit, reviewable changes over hidden automation.
      '';

      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        autoupdate = false;
        instructions = [ "${config.xdg.configHome}/agents/AGENTS.md" ];
        permission = {
          "*" = "ask";
          glob = "allow";
          grep = "allow";
          list = "allow";
          lsp = "allow";
          read = "allow";
          skill = "allow";
          task = "allow";
          todoread = "allow";
          todowrite = "allow";
          webfetch = "allow";
          websearch = "allow";
        };
      };
    };

  flake.homeModules."claude-code" =
    { config, pkgs, ... }:
    let
      claudeHome = "${config.home.homeDirectory}/.claude";
    in
    {
      home.packages = [ pkgs."claude-code" ];

      home.file.".claude/CLAUDE.md".text = ''
        # TODO Custom Agent

        Shared instructions for Dave's coding agents.

        - Preserve the repo's intended folder structure and naming.
        - Prefer declarative Nix and Home Manager changes over ad-hoc local fixes.
        - Keep release notes, changelogs, and migration notes aligned with real code changes.
        - Default to XDG-aware config locations when the tool supports them.
        - Make the smallest correct change first, then tighten style and structure.
        - Prefer explicit, reviewable changes over hidden automation.
      '';

      home.file.".claude/settings.json".text = builtins.toJSON {
        permissions.allow = [
          "Glob"
          "Grep"
          "Read"
          "LSP"
          "WebFetch"
          "WebSearch"
          "TaskCreate"
          "TaskUpdate"
          "TaskGet"
          "TaskList"
          "TaskOutput"
          "TaskStop"
        ];
        env = {
          CLAUDE_BASH_NO_LOGIN = "1";
          CLAUDE_CODE_EAGER_FLUSH = "1";
          DISABLE_AUTOUPDATER = "1";
          DISABLE_TELEMETRY = "1";
          DISABLE_INSTALLATION_CHECKS = "1";
          USE_BUILTIN_RIPGREP = "0";
        };
      };

      home.file.".claude.json".text = builtins.toJSON {
        autoConnectIde = true;
        autoInstallIdeExtension = true;
      };

      home.sessionVariables.CLAUDE_CONFIG_DIR = claudeHome;
    };

  flake.homeModules.codex =
    { config, pkgs, ... }:
    let
      codexHome = "${config.home.homeDirectory}/.codex";
    in
    {
      home.packages = [ pkgs.codex ];

      home.sessionVariables.CODEX_HOME = codexHome;

      home.file.".codex/config.toml".text = ''
        [features]
        child_agents_md = true
      '';

      home.file.".codex/plugins/README.md".text = "Drop Codex plugins here when you want them managed declaratively.\n";
      home.file.".codex/agents/README.md".text = "Drop Codex agent presets here when you want them managed declaratively.\n";
    };

  flake.homeModules.pi =
    { pkgs, ... }:
    {
      home.packages = [ pkgs."pi-coding-agent" ];

      home.file.".pi/agent/settings.json".text = builtins.toJSON {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.4";
        defaultThinkingLevel = "high";
        skills = [
          "~/.codex/skills"
          "~/.claude/skills"
        ];
      };
    };
}
