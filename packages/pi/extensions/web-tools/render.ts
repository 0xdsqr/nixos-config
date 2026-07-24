import { keyHint } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

interface Theme {
  bold(value: string): string;
  fg(
    name: "accent" | "dim" | "error" | "muted" | "success" | "toolOutput" | "toolTitle" | "warning",
    value: string,
  ): string;
}

export function textContent(
  content: ReadonlyArray<{ type: string; text?: string }> | undefined,
): string {
  return content
    ?.filter((item) => item.type === "text" && typeof item.text === "string")
    .map((item) => item.text)
    .join("\n")
    .trim() ?? "";
}

export function preview(value: string, maximumLines: number, maximumColumns: number): string {
  return value
    .split(/\r?\n/)
    .slice(0, maximumLines)
    .map((line) => line.length > maximumColumns ? `${line.slice(0, maximumColumns - 1)}…` : line)
    .join("\n");
}

export function renderCall(
  tool: "webfetch" | "websearch",
  subject: string,
  suffix: string,
  theme: Theme,
) {
  let text = theme.fg("toolTitle", theme.bold(`${tool} `));
  text += theme.fg("accent", subject);
  if (suffix) text += theme.fg("muted", ` ${suffix}`);
  return new Text(text, 0, 0);
}

export function renderResult(
  label: string,
  result: { content: Array<{ type: string; text?: string }> },
  options: { expanded: boolean; isPartial: boolean },
  theme: Theme,
  metadata: string,
  isError = false,
) {
  if (options.isPartial) return new Text(theme.fg("warning", `${label}…`), 0, 0);
  const content = textContent(result.content);
  if (isError) return new Text(theme.fg("error", `✗ ${content || `${label} failed`}`), 0, 0);

  let text = theme.fg("success", `✓ ${label}`);
  if (metadata) text += theme.fg("muted", ` ${metadata}`);
  if (options.expanded && content) {
    text += `\n${theme.fg("toolOutput", preview(content, 24, 220))}`;
  } else {
    text += ` (${keyHint("app.tools.expand", "for details")})`;
  }
  return new Text(text, 0, 0);
}
