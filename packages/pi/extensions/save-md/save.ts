import { open, realpath } from "node:fs/promises";
import { basename, dirname, extname, isAbsolute, join, relative, resolve } from "node:path";

interface TextPart {
  text: string;
  type: "text";
}

interface AssistantLike {
  content: unknown[];
  role: "assistant";
  stopReason?: string;
}

interface MessageEntryLike {
  message: unknown;
  type: "message";
}

export class SaveMarkdownError extends Error {
  readonly code: "exists" | "invalid-path" | "missing-parent" | "write-failed";

  constructor(
    message: string,
    code: "exists" | "invalid-path" | "missing-parent" | "write-failed",
  ) {
    super(message);
    this.code = code;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isMessageEntry(value: unknown): value is MessageEntryLike {
  return isRecord(value) && value.type === "message" && "message" in value;
}

function isAssistant(value: unknown): value is AssistantLike {
  return isRecord(value) && value.role === "assistant" && Array.isArray(value.content);
}

function isTextPart(value: unknown): value is TextPart {
  return isRecord(value) && value.type === "text" && typeof value.text === "string";
}

export function latestCompletedAssistantMarkdown(branch: readonly unknown[]): string | undefined {
  for (let index = branch.length - 1; index >= 0; index -= 1) {
    const entry = branch[index];
    if (!isMessageEntry(entry) || !isAssistant(entry.message)) continue;
    if (
      entry.message.stopReason === "error"
      || entry.message.stopReason === "aborted"
      || entry.message.stopReason === "toolUse"
    ) {
      continue;
    }

    const text = entry.message.content
      .filter(isTextPart)
      .map((part) => part.text)
      .join("\n\n")
      .trimEnd();
    if (text.trim()) return text;
  }
  return undefined;
}

function isWithin(parent: string, child: string): boolean {
  const path = relative(parent, child);
  return path === "" || (!path.startsWith(`..${process.platform === "win32" ? "\\" : "/"}`) && path !== ".." && !isAbsolute(path));
}

export async function resolveSafeMarkdownPath(cwd: string, requestedName: string): Promise<string> {
  const trimmed = requestedName.trim();
  if (!trimmed || trimmed.includes("\0") || isAbsolute(trimmed)) {
    throw new SaveMarkdownError("Provide a non-empty path relative to the current workspace", "invalid-path");
  }

  const withExtension = extname(trimmed).toLowerCase() === ".md" ? trimmed : `${trimmed}.md`;
  const fileName = basename(withExtension);
  if (!fileName || fileName === "." || fileName === "..") {
    throw new SaveMarkdownError("Provide a Markdown file name, not a directory", "invalid-path");
  }

  const realCwd = await realpath(cwd);
  const candidate = resolve(realCwd, withExtension);
  let realParent: string;
  try {
    realParent = await realpath(dirname(candidate));
  } catch {
    throw new SaveMarkdownError("The destination directory does not exist", "missing-parent");
  }
  if (!isWithin(realCwd, realParent)) {
    throw new SaveMarkdownError("The destination must remain inside the current workspace", "invalid-path");
  }
  return join(realParent, fileName);
}

export async function saveMarkdown(
  cwd: string,
  requestedName: string,
  markdown: string,
): Promise<string> {
  const path = await resolveSafeMarkdownPath(cwd, requestedName);
  let handle;
  try {
    handle = await open(path, "wx", 0o600);
    await handle.writeFile(markdown.endsWith("\n") ? markdown : `${markdown}\n`, "utf8");
  } catch (error) {
    if (isRecord(error) && error.code === "EEXIST") {
      throw new SaveMarkdownError(`File already exists: ${path}`, "exists");
    }
    if (error instanceof SaveMarkdownError) throw error;
    throw new SaveMarkdownError(`Could not save Markdown to ${path}`, "write-failed");
  } finally {
    await handle?.close();
  }
  return path;
}
