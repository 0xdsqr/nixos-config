import { join } from "node:path";

import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { cloakText, loadCloakState, toolResultPaths } from "./cloak.ts";

export default function cloakExtension(pi: ExtensionAPI): void {
  const configPath = join(getAgentDir(), "cloak.json");
  let state = loadCloakState(configPath);
  let redactions = 0;
  let resultsChanged = 0;

  const reload = () => {
    state = loadCloakState(configPath);
  };

  pi.on("session_start", (_event, ctx) => {
    reload();
    if (state.errors.length > 0 && ctx.hasUI) {
      ctx.ui.notify(`Cloak loaded safe defaults with ${state.errors.length} config warning(s)`, "warning");
    }
  });

  pi.registerCommand("cloak-status", {
    description: "Show Cloak configuration and redaction status",
    handler: async (_args, ctx) => {
      const summary = [
        `enabled=${state.config.enabled}`,
        `rules=${state.rules.length}`,
        `customPatterns=${state.patterns.length}`,
        `changedResults=${resultsChanged}`,
        `redactions=${redactions}`,
        `warnings=${state.errors.length}`,
        `config=${state.configPath}`,
      ].join(" ");
      ctx.ui.notify(summary, state.errors.length > 0 ? "warning" : "info");
    },
  });

  pi.registerCommand("cloak-reload", {
    description: "Reload Cloak configuration",
    handler: async (_args, ctx) => {
      reload();
      ctx.ui.notify(
        state.errors.length > 0
          ? `Cloak reloaded safe defaults with ${state.errors.length} warning(s)`
          : `Cloak reloaded ${state.rules.length} rules`,
        state.errors.length > 0 ? "warning" : "info",
      );
    },
  });

  pi.on("tool_result", (event, ctx) => {
    if (!state.config.enabled) return;

    let changed = false;
    const content = event.content.map((part: { type: string; text?: string }) => {
      if (part.type !== "text" || typeof part.text !== "string") return part;
      const paths = toolResultPaths(event.toolName, event.input, ctx.cwd, part.text);
      const result = cloakText(part.text, paths, ctx.cwd, state);
      if (result.replacements === 0) return part;
      changed = true;
      redactions += result.replacements;
      return { ...part, text: result.text };
    });

    if (!changed) return;
    resultsChanged += 1;
    return { content };
  });
}
