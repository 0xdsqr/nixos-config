import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import {
  latestCompletedAssistantMarkdown,
  saveMarkdown,
  SaveMarkdownError,
} from "./save.ts";

export default function saveMarkdownExtension(pi: ExtensionAPI): void {
  pi.registerCommand("save-md", {
    description: "Save the latest completed assistant response as Markdown",
    handler: async (args, ctx) => {
      const requestedName = args.trim();
      if (!requestedName) {
        ctx.ui.notify("Usage: /save-md path/name", "warning");
        return;
      }

      await ctx.waitForIdle();
      const markdown = latestCompletedAssistantMarkdown(ctx.sessionManager.getBranch());
      if (!markdown) {
        ctx.ui.notify("No completed assistant Markdown response is available", "warning");
        return;
      }

      try {
        const path = await saveMarkdown(ctx.cwd, requestedName, markdown);
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
