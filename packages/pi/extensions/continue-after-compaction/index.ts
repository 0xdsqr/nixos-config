import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export interface CompactionEvent {
  compactionEntry: { id: string };
  reason: "manual" | "overflow" | "threshold";
  willRetry: boolean;
}

type Timer = ReturnType<typeof setTimeout>;

export function shouldContinueAfterCompaction(event: CompactionEvent): boolean {
  // Overflow recovery already retries the interrupted turn in Pi itself.
  return !event.willRetry;
}

export function buildContinuationPrompt(
  sessionFile: string | undefined,
  event: CompactionEvent,
): string {
  const sessionSource = sessionFile
    ? [
        `The persisted session JSONL is ${JSON.stringify(sessionFile)}.`,
        "Consult it only if the compaction summary and current worktree are insufficient.",
        "Follow parentId links when reconstructing the active branch; append order may contain abandoned branches.",
        "Do not start a nested Pi process.",
      ].join(" ")
    : "This session is ephemeral, so no persisted session JSONL is available.";

  return `Context compaction has completed. Continue the existing task without waiting for another user prompt.

Compaction entry: ${JSON.stringify(event.compactionEntry.id)}
Compaction reason: ${event.reason}
${sessionSource}

Reconstruct the active goal, user constraints, decisions, completed edits and checks, unresolved work, and the next intended action. Treat the current worktree as authoritative for file state and the active session branch as authoritative for user intent. Briefly state what you recovered, then immediately perform the next unfinished step. Do not stop after a recap or ask the user to repeat context unless the available state is genuinely ambiguous.`;
}

export default function continueAfterCompaction(pi: ExtensionAPI): void {
  const pending = new Map<string, Timer>();
  const seen = new Set<string>();

  pi.on("session_compact", (event, ctx) => {
    if (!shouldContinueAfterCompaction(event) || seen.has(event.compactionEntry.id)) return;

    seen.add(event.compactionEntry.id);
    if (seen.size > 128) {
      const oldest = seen.values().next().value;
      if (oldest) seen.delete(oldest);
    }

    const prompt = buildContinuationPrompt(ctx.sessionManager.getSessionFile(), event);
    const timer = setTimeout(() => {
      pending.delete(event.compactionEntry.id);
      pi.sendUserMessage(prompt, { deliverAs: "followUp" });
    }, 0);
    pending.set(event.compactionEntry.id, timer);
  });

  pi.on("session_shutdown", () => {
    for (const timer of pending.values()) clearTimeout(timer);
    pending.clear();
  });
}
