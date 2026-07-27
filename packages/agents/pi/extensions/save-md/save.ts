import {
  chmod,
  lstat,
  mkdir,
  open,
  readFile,
  realpath,
} from "node:fs/promises";
import { basename, dirname, extname, isAbsolute, join, relative, resolve } from "node:path";

export interface SaveMarkdownArguments {
  destination: "library" | "workspace";
  requestedName: string;
}

interface SaveMarkdownConfig {
  libraryDirectory?: string | null;
}

interface LibraryDirectoryOptions {
  configPath: string;
  home: string;
  platform: NodeJS.Platform;
  xdgConfigHome?: string;
}

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
  readonly code:
    | "config-error"
    | "exists"
    | "invalid-path"
    | "missing-parent"
    | "unsafe-library"
    | "write-failed";

  constructor(
    message: string,
    code:
      | "config-error"
      | "exists"
      | "invalid-path"
      | "missing-parent"
      | "unsafe-library"
      | "write-failed",
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

function errorCode(error: unknown): string | undefined {
  return isRecord(error) && typeof error.code === "string" ? error.code : undefined;
}

export function parseSaveMarkdownArguments(args: string): SaveMarkdownArguments {
  const trimmed = args.trim();
  const libraryMatch = trimmed.match(/^(?:--library|-l)(?:\s+|$)/);
  const destination = libraryMatch ? "library" : "workspace";
  const requestedName = libraryMatch ? trimmed.slice(libraryMatch[0].length).trim() : trimmed;

  if (!requestedName) {
    throw new SaveMarkdownError(
      "Usage: /save-md [--library|-l] path/name",
      "invalid-path",
    );
  }

  return { destination, requestedName };
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

function expandHome(path: string, home: string): string {
  if (path === "~") return home;
  if (path.startsWith("~/")) return join(home, path.slice(2));
  return path;
}

export function parseXdgDocumentsDirectory(contents: string, home: string): string | undefined {
  const match = contents.match(/^\s*XDG_DOCUMENTS_DIR\s*=\s*"([^"]*)"\s*$/m);
  if (!match) return undefined;

  const expanded = match[1]
    .replace(/^\$HOME(?=\/|$)/, home)
    .replace(/^\$\{HOME\}(?=\/|$)/, home);
  if (!expanded || expanded.includes("\0") || expanded.includes("$") || !isAbsolute(expanded)) {
    return undefined;
  }
  return resolve(expanded);
}

export function defaultLibraryDirectory(
  platform: NodeJS.Platform,
  home: string,
  xdgDocumentsDirectory?: string,
): string {
  const documentsDirectory =
    platform === "linux" && xdgDocumentsDirectory
      ? xdgDocumentsDirectory
      : join(home, "Documents");
  return join(documentsDirectory, "Pi");
}

async function loadConfig(configPath: string): Promise<SaveMarkdownConfig> {
  let raw: string;
  try {
    raw = await readFile(configPath, "utf8");
  } catch (error) {
    if (errorCode(error) === "ENOENT") return {};
    throw new SaveMarkdownError(`Could not read save-md config: ${configPath}`, "config-error");
  }

  try {
    const parsed: unknown = JSON.parse(raw);
    if (!isRecord(parsed)) throw new Error("not an object");
    if (
      parsed.libraryDirectory !== undefined
      && parsed.libraryDirectory !== null
      && typeof parsed.libraryDirectory !== "string"
    ) {
      throw new Error("libraryDirectory must be a string or null");
    }
    return parsed;
  } catch {
    throw new SaveMarkdownError(
      `Invalid save-md config in ${configPath}: libraryDirectory must be a string or null`,
      "config-error",
    );
  }
}

export async function resolveLibraryDirectory(
  options: LibraryDirectoryOptions,
): Promise<string> {
  const config = await loadConfig(options.configPath);
  if (typeof config.libraryDirectory === "string") {
    const configured = expandHome(config.libraryDirectory.trim(), options.home);
    if (!configured || configured.includes("\0") || !isAbsolute(configured)) {
      throw new SaveMarkdownError(
        "save-md libraryDirectory must be an absolute path or start with ~/",
        "config-error",
      );
    }
    return resolve(configured);
  }

  let xdgDocumentsDirectory: string | undefined;
  if (options.platform === "linux") {
    const xdgConfigHome =
      options.xdgConfigHome && isAbsolute(options.xdgConfigHome)
        ? options.xdgConfigHome
        : join(options.home, ".config");
    try {
      const contents = await readFile(join(xdgConfigHome, "user-dirs.dirs"), "utf8");
      xdgDocumentsDirectory = parseXdgDocumentsDirectory(contents, options.home);
    } catch {
      // XDG user directories are optional; fall back to ~/Documents.
    }
  }

  return defaultLibraryDirectory(options.platform, options.home, xdgDocumentsDirectory);
}

export async function ensurePrivateLibraryDirectory(path: string): Promise<string> {
  try {
    const existing = await lstat(path);
    if (existing.isSymbolicLink()) {
      throw new SaveMarkdownError(
        `Refusing symlinked Pi document library: ${path}`,
        "unsafe-library",
      );
    }
    if (!existing.isDirectory()) {
      throw new SaveMarkdownError(
        `Pi document library is not a directory: ${path}`,
        "unsafe-library",
      );
    }
  } catch (error) {
    if (error instanceof SaveMarkdownError) throw error;
    if (errorCode(error) !== "ENOENT") {
      throw new SaveMarkdownError(
        `Could not inspect Pi document library: ${path}`,
        "unsafe-library",
      );
    }
    try {
      await mkdir(path, { mode: 0o700, recursive: true });
    } catch {
      throw new SaveMarkdownError(
        `Could not create Pi document library: ${path}`,
        "unsafe-library",
      );
    }
  }

  let directory;
  try {
    directory = await lstat(path);
  } catch {
    throw new SaveMarkdownError(
      `Could not inspect Pi document library after creation: ${path}`,
      "unsafe-library",
    );
  }
  if (directory.isSymbolicLink() || !directory.isDirectory()) {
    throw new SaveMarkdownError(
      `Pi document library is not a private directory: ${path}`,
      "unsafe-library",
    );
  }

  const currentUid = process.getuid?.();
  if (currentUid !== undefined && directory.uid !== currentUid) {
    throw new SaveMarkdownError(
      `Pi document library is not owned by the current user: ${path}`,
      "unsafe-library",
    );
  }

  try {
    await chmod(path, 0o700);
    return await realpath(path);
  } catch {
    throw new SaveMarkdownError(
      `Could not secure Pi document library: ${path}`,
      "unsafe-library",
    );
  }
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
    await handle.chmod(0o600);
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
