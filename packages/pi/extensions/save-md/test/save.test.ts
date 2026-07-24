import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, realpath, stat, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  latestCompletedAssistantMarkdown,
  resolveSafeMarkdownPath,
  saveMarkdown,
  SaveMarkdownError,
} from "../save.ts";

test("latest response includes text only and skips aborted assistant messages", () => {
  const branch = [
    {
      type: "message",
      message: {
        role: "assistant",
        stopReason: "stop",
        content: [
          { type: "thinking", thinking: "private" },
          { type: "text", text: "# Finished" },
          { type: "toolCall", name: "read" },
          { type: "text", text: "Body" },
        ],
      },
    },
    {
      type: "message",
      message: {
        role: "assistant",
        stopReason: "aborted",
        content: [{ type: "text", text: "Partial response" }],
      },
    },
    {
      type: "message",
      message: {
        role: "assistant",
        stopReason: "toolUse",
        content: [{ type: "text", text: "I will now read a file." }],
      },
    },
  ];
  assert.equal(latestCompletedAssistantMarkdown(branch), "# Finished\n\nBody");
});

test("safe path resolution remains within the real workspace", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-"));
  const docs = join(root, "docs");
  const outside = await mkdtemp(join(tmpdir(), "pi-save-md-outside-"));
  await mkdir(docs);
  await symlink(outside, join(root, "escape"));

  assert.equal(await resolveSafeMarkdownPath(root, "docs/report"), join(await realpath(docs), "report.md"));
  await assert.rejects(
    () => resolveSafeMarkdownPath(root, "../outside"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "invalid-path",
  );
  await assert.rejects(
    () => resolveSafeMarkdownPath(root, "escape/report"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "invalid-path",
  );
});

test("saving creates a private Markdown file and never overwrites it", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-"));
  const path = await saveMarkdown(root, "answer", "Hello");
  assert.equal(await readFile(path, "utf8"), "Hello\n");
  assert.equal((await stat(path)).mode & 0o777, 0o600);
  await assert.rejects(
    () => saveMarkdown(root, "answer.md", "Replacement"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "exists",
  );
  assert.equal(await readFile(path, "utf8"), "Hello\n");
});

test("missing parent directories are rejected rather than created implicitly", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-"));
  await assert.rejects(
    () => saveMarkdown(root, "missing/report", "Hello"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "missing-parent",
  );
});
