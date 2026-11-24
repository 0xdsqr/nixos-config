{
  flake.homeModules.agent-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.attrsets) attrNames filterAttrs mapAttrs optionalAttrs;
      inherit (lib.lists) elem optional;
      inherit (lib.modules) mkDefault mkIf mkMerge;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types)
        attrsOf
        enum
        listOf
        nullOr
        str
        submodule
        ;

      cfg = config.dsqr.home.agentMcp;
      jsonFormat = pkgs.formats.json { };
      catalog = import ../../packages/agents/mcp;

      # Pi has no MCP client, so it is not a target.
      targetType = listOf (enum [
        "claude"
        "codex"
        "opencode"
      ]);

      serverModule =
        { name, ... }:
        {
          options = {
            enable = mkEnableOption "the ${name} MCP server" // {
              default = true;
            };

            targets = mkOption {
              type = targetType;
              default = cfg.defaultTargets;
              defaultText = lib.literalExpression "config.dsqr.home.agentMcp.defaultTargets";
              description = "Agent runtimes that get the ${name} MCP server.";
            };

            url = mkOption {
              type = nullOr str;
              default = null;
              description = "Remote (streamable HTTP) server URL. Mutually exclusive with `command`.";
            };

            headers = mkOption {
              type = attrsOf str;
              default = { };
              description = "HTTP headers sent to a remote server.";
            };

            command = mkOption {
              type = nullOr str;
              default = null;
              description = "Executable for a local stdio server. Mutually exclusive with `url`.";
            };

            args = mkOption {
              type = listOf str;
              default = [ ];
              description = "Arguments for a local stdio server.";
            };

            env = mkOption {
              type = attrsOf str;
              default = { };
              description = "Environment for a local stdio server.";
            };
          };
        };

      serversFor = target: filterAttrs (_: server: server.enable && elem target server.targets) cfg.servers;

      isRemote = server: server.url != null;

      toClaude =
        server:
        if isRemote server then
          {
            type = "http";
            inherit (server) url;
          }
          // optionalAttrs (server.headers != { }) { inherit (server) headers; }
        else
          {
            type = "stdio";
            inherit (server) command args;
          }
          // optionalAttrs (server.env != { }) { inherit (server) env; };

      toCodex =
        server:
        if isRemote server then
          { inherit (server) url; } // optionalAttrs (server.headers != { }) { http_headers = server.headers; }
        else
          { inherit (server) command args; } // optionalAttrs (server.env != { }) { inherit (server) env; };

      toOpencode =
        server:
        {
          enabled = true;
        }
        // (
          if isRemote server then
            {
              type = "remote";
              inherit (server) url;
            }
            // optionalAttrs (server.headers != { }) { inherit (server) headers; }
          else
            {
              type = "local";
              command = [ server.command ] ++ server.args;
            }
            // optionalAttrs (server.env != { }) { environment = server.env; }
        );

      claudeServers = mapAttrs (_: toClaude) (serversFor "claude");
      codexServers = mapAttrs (_: toCodex) (serversFor "codex");
      opencodeServers = mapAttrs (_: toOpencode) (serversFor "opencode");

      # Claude Code (>= 2.1.157) loads every directory under
      # $CLAUDE_CONFIG_DIR/skills that carries a plugin manifest as a personal
      # plugin, so the MCP servers ship as one generated plugin. That keeps
      # them out of the mutable ~/.claude.json. The short manifest name keeps
      # tool names compact: mcp__plugin_dsqr_<server>__<tool>.
      claudePlugin = pkgs.runCommandLocal "claude-code-dsqr-mcp" { } ''
        install -Dm644 ${jsonFormat.generate "claude-code-mcp-plugin.json" { name = "dsqr"; }} \
          "$out/.claude-plugin/plugin.json"
        install -Dm644 ${jsonFormat.generate "claude-code-mcp.json" { mcpServers = claudeServers; }} \
          "$out/.mcp.json"
      '';
    in
    {
      options.dsqr.home.agentMcp = {
        defaultTargets = mkOption {
          type = targetType;
          default =
            optional (config.dsqr.home.claudeCode.enable or false) "claude"
            ++ optional (config.dsqr.home.codex.enable or false) "codex"
            ++ optional (config.dsqr.home.opencode.enable or false) "opencode";
          defaultText = lib.literalMD "every enabled agent among Claude Code, Codex, and OpenCode";
          description = "Targets for MCP servers that do not set their own `targets`.";
        };

        servers = mkOption {
          type = attrsOf (submodule serverModule);
          default = { };
          description = ''
            MCP servers installed for the enabled agents. The shared catalog in
            packages/agents/mcp is always present; override an entry (for example
            `servers.superlogical.enable = false`) or add host-specific ones here.
          '';
        };
      };

      config = mkMerge [
        { dsqr.home.agentMcp.servers = mapAttrs (_: mapAttrs (_: mkDefault)) catalog; }

        {
          assertions = map (name: {
            assertion = (cfg.servers.${name}.url != null) != (cfg.servers.${name}.command != null);
            message = "dsqr.home.agentMcp.servers.${name}: set exactly one of `url` or `command`.";
          }) (attrNames cfg.servers);
        }

        (mkIf (claudeServers != { }) {
          xdg.configFile."claude-code/skills/dsqr-mcp".source = claudePlugin;
        })

        # Home Manager merges these into Codex's mutable config.toml, so
        # project trust and other runtime state survive activation.
        (mkIf (codexServers != { }) { programs.codex.settings.mcp_servers = codexServers; })

        (mkIf (opencodeServers != { }) { programs.opencode.settings.mcp = opencodeServers; })
      ];
    };
}
