import { parsePublicUrl } from "../network.ts";
import { WEB_TOOLS_SETTINGS } from "../settings.ts";

export interface SearchResult {
  published?: string;
  score?: number;
  snippet?: string;
  source?: string;
  title: string;
  url: string;
}

function metadata(value: string | undefined): string | undefined {
  const cleaned = value?.trim();
  if (!cleaned || /^(n\/a|na|none|null|undefined|unknown)$/i.test(cleaned)) return undefined;
  return cleaned;
}

function snippet(value: string, title: string): string | undefined {
  let cleaned = value
    .replace(/^\s*---+\s*$/gm, "")
    .replace(/^#+\s+/gm, "")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  while (title && cleaned.split("\n")[0]?.trim().toLowerCase() === title.toLowerCase()) {
    cleaned = cleaned.split("\n").slice(1).join("\n").trim();
  }
  if (!cleaned) return undefined;
  const limit = WEB_TOOLS_SETTINGS.search.snippetCharacters;
  return cleaned.length <= limit ? cleaned : `${cleaned.slice(0, limit - 3).trimEnd()}...`;
}

export function isExplicitNoResults(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  return !normalized || normalized.startsWith("no results found") || normalized.includes("no relevant results");
}

export function parseSearchResults(input: string): SearchResult[] {
  const starts = [...input.matchAll(/^Title:\s*/gm)].map((match) => match.index ?? 0);
  return starts.flatMap((start, index) => {
    const section = input.slice(start, starts[index + 1] ?? input.length);
    const title = section.match(/^Title:\s*(.+)$/m)?.[1]?.trim() ?? "";
    const rawUrl = section.match(/^URL:\s*(.+)$/m)?.[1]?.trim() ?? "";
    if (!rawUrl) return [];

    let url: string;
    try {
      url = parsePublicUrl(rawUrl).href;
    } catch {
      return [];
    }

    const textStart = section.search(/^(Text|Highlights):\s*/m);
    const rawSnippet = textStart >= 0
      ? section.slice(textStart).replace(/^(Text|Highlights):\s*/m, "")
      : "";
    const rawScore = section.match(/^Score:\s*(.+)$/m)?.[1]?.trim();
    const score = rawScore ? Number.parseFloat(rawScore) : undefined;
    const result: SearchResult = { title: title || url, url };
    const published = metadata(section.match(/^Published(?: Date)?:\s*(.+)$/m)?.[1]);
    const source = metadata(section.match(/^(?:Source|Author):\s*(.+)$/m)?.[1]);
    const summary = snippet(rawSnippet, title);
    if (published) result.published = published;
    if (source) result.source = source;
    if (Number.isFinite(score)) result.score = score;
    if (summary) result.snippet = summary;
    return [result];
  });
}

export function formatSearchResults(query: string, results: readonly SearchResult[]): string {
  if (!results.length) return `Search results for: ${query}\n\nNo results found.`;
  const lines = [`Search results for: ${query}`, ""];
  results.forEach((result, index) => {
    lines.push(`${index + 1}. ${result.title}`, `   URL: ${result.url}`);
    if (result.published) lines.push(`   Published: ${result.published}`);
    if (result.source) lines.push(`   Source: ${result.source}`);
    if (result.score !== undefined) lines.push(`   Score: ${result.score}`);
    if (result.snippet) lines.push(`   Snippet: ${result.snippet.replace(/\n+/g, "\n   ")}`);
    lines.push("");
  });
  return lines.join("\n").trimEnd();
}
