import { homedir } from "node:os";
import { join } from "node:path";

import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

import {
  ensurePrivateLibraryDirectory,
  latestCompletedAssistantMarkdown,
  parseSaveMarkdownArguments,
  resolveLibraryDirectory,
  saveMarkdown,
  SaveMarkdownError,
} from "./save.ts";

export default function saveMarkdownExtension(pi: ExtensionAPI): void {
  const configPath = join(getAgentDir(), "save-md.json");

  pi.registerCommand("save-md", {
    description: "Save the latest response as Markdown; use --library for private Documents/Pi storage",
    handler: async (args, ctx) => {
      let parsed;
      try {
        parsed = parseSaveMarkdownArguments(args);
      } catch (error) {
        ctx.ui.notify(
          error instanceof SaveMarkdownError ? error.message : "Invalid save-md arguments",
          "warning",
        );
        return;
      }

      await ctx.waitForIdle();
      const markdown = latestCompletedAssistantMarkdown(ctx.sessionManager.getBranch());
      if (!markdown) {
        ctx.ui.notify("No completed assistant Markdown response is available", "warning");
        return;
      }

      try {
        let destination = ctx.cwd;
        if (parsed.destination === "library") {
          const configuredLibrary = await resolveLibraryDirectory({
            configPath,
            home: homedir(),
            platform: process.platform,
            xdgConfigHome: process.env.XDG_CONFIG_HOME,
          });
          destination = await ensurePrivateLibraryDirectory(configuredLibrary);
        }

        const path = await saveMarkdown(destination, parsed.requestedName, markdown);
        ctx.ui.notify(`Saved Markdown to ${path}`, "info");
      } catch (error) {
        ctx.ui.notify(
          error instanceof SaveMarkdownError ? error.message : "Could not save the Markdown response",
          "error",
        );
      }
    },
  });
}
