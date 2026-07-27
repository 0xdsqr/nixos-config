import assert from "node:assert/strict";
import {
  lstat,
  mkdtemp,
  mkdir,
  readFile,
  realpath,
  stat,
  symlink,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  defaultLibraryDirectory,
  ensurePrivateLibraryDirectory,
  latestCompletedAssistantMarkdown,
  parseSaveMarkdownArguments,
  parseXdgDocumentsDirectory,
  resolveLibraryDirectory,
  resolveSafeMarkdownPath,
  saveMarkdown,
  SaveMarkdownError,
} from "../save.ts";

test("save arguments preserve workspace behavior and support a library option", () => {
  assert.deepEqual(parseSaveMarkdownArguments("notes/answer"), {
    destination: "workspace",
    requestedName: "notes/answer",
  });
  assert.deepEqual(parseSaveMarkdownArguments("--library project answer"), {
    destination: "library",
    requestedName: "project answer",
  });
  assert.deepEqual(parseSaveMarkdownArguments("-l notes/answer"), {
    destination: "library",
    requestedName: "notes/answer",
  });
  assert.throws(
    () => parseSaveMarkdownArguments("--library"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "invalid-path",
  );
});

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

test("platform defaults use Documents/Pi and honor Linux XDG user directories", () => {
  const home = "/home/pi-user";
  const xdgDocuments = parseXdgDocumentsDirectory(
    'XDG_DESKTOP_DIR="$HOME/Desktop"\nXDG_DOCUMENTS_DIR="${HOME}/Documents and Notes"\n',
    home,
  );
  assert.equal(xdgDocuments, "/home/pi-user/Documents and Notes");
  assert.equal(
    defaultLibraryDirectory("darwin", "/Users/pi-user", "/ignored"),
    "/Users/pi-user/Documents/Pi",
  );
  assert.equal(
    defaultLibraryDirectory("linux", home, xdgDocuments),
    "/home/pi-user/Documents and Notes/Pi",
  );
  assert.equal(defaultLibraryDirectory("linux", home), "/home/pi-user/Documents/Pi");
});

test("configured library paths support home expansion", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-config-"));
  const configPath = join(root, "save-md.json");
  await writeFile(configPath, '{"libraryDirectory":"~/Private/Pi"}', "utf8");

  assert.equal(
    await resolveLibraryDirectory({
      configPath,
      home: "/Users/pi-user",
      platform: "darwin",
    }),
    "/Users/pi-user/Private/Pi",
  );
});

test("library creation is private and saved files remain exclusive", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-library-"));
  const requestedLibrary = join(root, "Documents", "Pi");
  const library = await ensurePrivateLibraryDirectory(requestedLibrary);
  assert.equal((await stat(library)).mode & 0o777, 0o700);

  const path = await saveMarkdown(library, "answer", "Private");
  assert.equal(await readFile(path, "utf8"), "Private\n");
  assert.equal((await stat(path)).mode & 0o777, 0o600);
  await assert.rejects(
    () => saveMarkdown(library, "answer", "Replacement"),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "exists",
  );
});

test("a symlink cannot be used as the library root", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-save-md-library-"));
  const actualLibrary = join(root, "actual");
  const linkedLibrary = join(root, "linked");
  await mkdir(actualLibrary);
  await symlink(actualLibrary, linkedLibrary);
  assert.equal((await lstat(linkedLibrary)).isSymbolicLink(), true);

  await assert.rejects(
    () => ensurePrivateLibraryDirectory(linkedLibrary),
    (error: unknown) => error instanceof SaveMarkdownError && error.code === "unsafe-library",
  );
});
