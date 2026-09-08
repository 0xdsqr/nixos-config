{
  flake.homeModules.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) optional;
      inherit (lib.modules) mkIf;
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.strings) escapeShellArg;
      inherit (lib.types) nullOr str;

      cfg = config.dsqr.home.herdr;
      layout = cfg.layouts.dev;
      herdr = if config.programs.herdr.package == null then "herdr" else getExe config.programs.herdr.package;

      devLayout = pkgs.writeShellApplication {
        name = "herdr-dev";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          herdr="''${HERDR_BIN_PATH:-${herdr}}"
          directory="''${HERDR_ACTIVE_PANE_CWD:-$PWD}"
          agent=${escapeShellArg layout.agent}
          agent_args=()

          usage() {
            printf '%s\n' 'Usage: herdr-dev [--cwd DIRECTORY] [--agent KIND] [-- AGENT_ARGS...]'
            printf '%s\n' 'Create a new workspace with an editor, agent, and shell in a running Herdr session.'
          }

          while (( $# > 0 )); do
            case "$1" in
              --cwd|--agent)
                if (( $# < 2 )); then
                  usage >&2
                  exit 2
                fi
                if [[ "$1" == --cwd ]]; then directory="$2"; else agent="$2"; fi
                shift 2
                ;;
              --)
                shift
                agent_args=("$@")
                break
                ;;
              -h|--help)
                usage
                exit 0
                ;;
              *)
                usage >&2
                exit 2
                ;;
            esac
          done

          directory="$(cd -- "$directory" && pwd -P)"
          label="''${directory##*/}"
          created="$("$herdr" workspace create --cwd "$directory" --label "''${label:-dev}" --no-focus)"
          workspace="$(jq -er '.result.workspace.workspace_id' <<< "$created")"

          finish() {
            local status=$?
            if (( status != 0 )); then
              "$herdr" workspace focus "$workspace" >/dev/null || true
              printf 'Layout setup stopped; workspace %s was preserved for inspection.\n' "$workspace" >&2
            fi
            exit "$status"
          }
          trap finish EXIT

          editor_pane="$(jq -er '.result.root_pane.pane_id' <<< "$created")"
          split="$("$herdr" pane split "$editor_pane" --direction right --ratio 0.60 --cwd "$directory" --no-focus)"
          agent_pane="$(jq -er '.result.pane.pane_id' <<< "$split")"
          split="$("$herdr" pane split "$agent_pane" --direction down --ratio 0.68 --cwd "$directory" --no-focus)"
          shell_pane="$(jq -er '.result.pane.pane_id' <<< "$split")"

          "$herdr" pane rename "$editor_pane" editor >/dev/null
          "$herdr" pane rename "$agent_pane" agent >/dev/null
          "$herdr" pane rename "$shell_pane" shell >/dev/null
          "$herdr" pane run "$editor_pane" ${escapeShellArg layout.editorCommand} >/dev/null

          agent_name="dev-''${agent_pane//:/-}"
          "$herdr" agent start "$agent_name" --kind "$agent" --pane "$agent_pane" -- "''${agent_args[@]}" >/dev/null
          "$herdr" agent focus "$agent_name" >/dev/null

          printf 'Created workspace %s: editor=%s agent=%s shell=%s\n' "$workspace" "$editor_pane" "$agent_pane" "$shell_pane"
        '';
      };
    in
    {
      options.dsqr.home.herdr.layouts.dev = {
        enable = mkEnableOption "the on-demand herdr-dev editor, agent, and shell layout";
        editorCommand = mkOption {
          type = str;
          default = "nvim .";
          description = "Command sent to the editor pane's interactive shell.";
        };
        agent = mkOption {
          type = str;
          default = "codex";
          description = "Default native Herdr agent kind; herdr-dev --agent overrides it for one launch.";
        };
        key = mkOption {
          type = nullOr str;
          default = "prefix+t";
          description = "Native Herdr keybinding for this layout; null disables the shortcut.";
        };
      };

      config = mkIf (cfg.enable && layout.enable) {
        home.packages = [ devLayout ];
        programs.herdr.settings.keys.command = optional (layout.key != null) {
          inherit (layout) key;
          type = "shell";
          command = getExe devLayout;
          description = "Open editor, agent, and shell workspace";
        };
      };
    };
}
