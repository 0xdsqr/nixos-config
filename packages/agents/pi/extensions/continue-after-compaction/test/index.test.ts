import assert from "node:assert/strict";
import test from "node:test";

import {
  buildContinuationPrompt,
  shouldContinueAfterCompaction,
  type CompactionEvent,
} from "../index.ts";

const manualEvent: CompactionEvent = {
  compactionEntry: { id: "compact-123" },
  reason: "manual",
  willRetry: false,
};

test("ordinary compaction schedules a continuation", () => {
  assert.equal(shouldContinueAfterCompaction(manualEvent), true);
  assert.equal(
    shouldContinueAfterCompaction({
      compactionEntry: { id: "overflow-1" },
      reason: "overflow",
      willRetry: true,
    }),
    false,
  );
});

test("continuation prompt carries safe branch-recovery instructions", () => {
  const prompt = buildContinuationPrompt("/tmp/session \"quoted\".jsonl", manualEvent);
  assert.match(prompt, /compact-123/);
  assert.match(prompt, /parentId links/);
  assert.match(prompt, /current worktree as authoritative/);
  assert.match(prompt, /\/tmp\/session \\"quoted\\"\.jsonl/);
  assert.doesNotMatch(prompt, /pi --session/);
});

test("ephemeral sessions do not invent a session path", () => {
  const prompt = buildContinuationPrompt(undefined, {
    compactionEntry: { id: "threshold-1" },
    reason: "threshold",
    willRetry: false,
  });
  assert.match(prompt, /ephemeral/);
  assert.doesNotMatch(prompt, /persisted session JSONL is "/);
});
