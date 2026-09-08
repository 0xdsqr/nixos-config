{
  flake.homeModules.herdr =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrByPath;
      inherit (lib.lists) optional;
      inherit (lib.meta) getExe;
      inherit (lib.modules) mkAfter mkIf mkMerge;
      inherit (lib.options) mkEnableOption;
      inherit (lib.strings)
        optionalString
        removePrefix
        replaceStrings
        versionAtLeast
        ;

      cfg = config.dsqr.home.herdr;
      inherit (cfg) integrations;
      herdrPackage = config.programs.herdr.package;
      anyEnabled =
        integrations.codex.enable || integrations.claude.enable || integrations.pi.enable || integrations.opencode.enable;
      hasOpenCodeTui = versionAtLeast herdrPackage.version "0.9.0";
      assets = "${herdrPackage.src}/src/integration/assets";
      codexDirectory =
        if config.home.preferXdgDirectories then "${config.xdg.configHome}/codex" else "${config.home.homeDirectory}/.codex";
      codexHook = "${codexDirectory}/herdr-agent-state.sh";
      codexHooksKey =
        if config.home.preferXdgDirectories then
          "${removePrefix config.home.homeDirectory config.xdg.configHome}/codex/hooks.json"
        else
          ".codex/hooks.json";
      claudeHook = "${config.xdg.configHome}/claude-code/hooks/herdr-agent-state.sh";
      sessionHook = path: {
        hooks = [
          {
            type = "command";
            command = "bash '${replaceStrings [ "'" ] [ "'\"'\"'" ] path}' session";
            timeout = 10;
          }
        ];
      };
      artifacts = pkgs.runCommand "herdr-${herdrPackage.version}-integrations" { } (
        ''
          mkdir -p "$out"
        ''
        + optionalString integrations.codex.enable ''
          mkdir -p "$out/codex"
          cp ${assets}/codex/herdr-agent-state.sh "$out/codex/herdr-agent-state.sh"
          substituteInPlace "$out/codex/herdr-agent-state.sh" \
            --replace-fail python3 ${getExe pkgs.python3}
        ''
        + optionalString integrations.claude.enable ''
          mkdir -p "$out/claude/hooks"
          cp ${assets}/claude/herdr-agent-state.sh "$out/claude/hooks/herdr-agent-state.sh"
          substituteInPlace "$out/claude/hooks/herdr-agent-state.sh" \
            --replace-fail python3 ${getExe pkgs.python3}
        ''
        + optionalString integrations.pi.enable ''
          mkdir -p "$out/pi/extensions"
          cp ${assets}/pi/herdr-agent-state.ts "$out/pi/extensions/herdr-agent-state.ts"
        ''
        + optionalString integrations.opencode.enable ''
          mkdir -p "$out/opencode/plugins"
          cp ${assets}/opencode/herdr-agent-state.js "$out/opencode/plugins/herdr-agent-state.js"
        ''
        + optionalString (integrations.opencode.enable && hasOpenCodeTui) ''
          cp ${assets}/opencode/herdr-tui-session.js "$out/opencode/herdr-tui-session.js"
        ''
      );
    in
    {
      options.dsqr.home.herdr.integrations = {
        codex.enable = mkEnableOption "Herdr's official Codex session hook";
        claude.enable = mkEnableOption "Herdr's official Claude Code session hook";
        pi.enable = mkEnableOption "Herdr's official Pi session and lifecycle extension";
        opencode.enable = mkEnableOption "Herdr's official OpenCode session and lifecycle plugins";
      };

      config = mkIf cfg.enable (
        mkMerge (
          [
            {
              home.packages = mkIf (integrations.codex.enable || integrations.claude.enable) [ pkgs.bash ];
              assertions = [
                {
                  assertion = !anyEnabled || (herdrPackage != null && herdrPackage ? src);
                  message = "Herdr integrations require programs.herdr.package with its upstream source.";
                }
                {
                  assertion = !integrations.codex.enable || config.programs.codex.enable;
                  message = "Herdr's Codex integration requires programs.codex.enable (or dsqr.home.codex.enable).";
                }
                {
                  assertion = !integrations.claude.enable || attrByPath [ "dsqr" "home" "claudeCode" "enable" ] false config;
                  message = "Herdr's Claude integration requires the claude-code home module and dsqr.home.claudeCode.enable.";
                }
                {
                  assertion = !integrations.pi.enable || attrByPath [ "programs" "pi" "enable" ] false config;
                  message = "Herdr's Pi integration requires the pi home module and programs.pi.enable.";
                }
                {
                  assertion = !integrations.opencode.enable || config.programs.opencode.enable;
                  message = "Herdr's OpenCode integration requires programs.opencode.enable (or dsqr.home.opencode.enable).";
                }
              ];
            }
            (mkIf integrations.codex.enable {
              programs.codex.hooks.SessionStart = mkAfter [ (sessionHook codexHook) ];
              home.file.${codexHooksKey}.target = "${codexDirectory}/hooks.json";
              home.file.${codexHook} = {
                source = "${artifacts}/codex/herdr-agent-state.sh";
                executable = true;
              };
            })
            (mkIf integrations.pi.enable {
              xdg.configFile."pi/agent/extensions/herdr-agent-state.ts".source = "${artifacts}/pi/extensions/herdr-agent-state.ts";
            })
            (mkIf integrations.opencode.enable {
              programs.opencode.tui.plugin = mkIf hasOpenCodeTui (mkAfter [ "./herdr-tui-session.js" ]);
              xdg.configFile = {
                "opencode/plugins/herdr-agent-state.js".source = "${artifacts}/opencode/plugins/herdr-agent-state.js";
                "opencode/herdr-tui-session.js" = mkIf hasOpenCodeTui { source = "${artifacts}/opencode/herdr-tui-session.js"; };
                "opencode/tui.json" = mkIf hasOpenCodeTui { target = "opencode/tui.jsonc"; };
              };
            })
          ]
          ++ optional (options ? dsqr.home.claudeCode.settings) (
            mkIf integrations.claude.enable {
              dsqr.home.claudeCode.settings.hooks.SessionStart = mkAfter [ ((sessionHook claudeHook) // { matcher = "*"; }) ];
              xdg.configFile."claude-code/hooks/herdr-agent-state.sh" = {
                source = "${artifacts}/claude/hooks/herdr-agent-state.sh";
                executable = true;
              };
            }
          )
        )
      );
    };
}
