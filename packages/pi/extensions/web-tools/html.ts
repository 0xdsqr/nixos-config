const ENTITY_NAMES: Readonly<Record<string, string>> = {
  amp: "&",
  apos: "'",
  gt: ">",
  lt: "<",
  nbsp: " ",
  quot: "\"",
};

function decodeEntities(value: string): string {
  return value.replace(/&(#x[\da-f]+|#\d+|[a-z]+);/gi, (entity, body: string) => {
    if (body.startsWith("#x") || body.startsWith("#X")) {
      const codePoint = Number.parseInt(body.slice(2), 16);
      return Number.isFinite(codePoint) && codePoint <= 0x10ffff ? String.fromCodePoint(codePoint) : entity;
    }
    if (body.startsWith("#")) {
      const codePoint = Number.parseInt(body.slice(1), 10);
      return Number.isFinite(codePoint) && codePoint <= 0x10ffff ? String.fromCodePoint(codePoint) : entity;
    }
    return ENTITY_NAMES[body.toLowerCase()] ?? entity;
  });
}

function stripTags(value: string): string {
  return value.replace(/<[^>]+>/g, "");
}

function removeNonContent(html: string): string {
  return html
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<(script|style|noscript|template|svg)\b[^>]*>[\s\S]*?<\/\1>/gi, "")
    .replace(/<(nav|footer|aside|form)\b[^>]*>[\s\S]*?<\/\1>/gi, "");
}

function chooseReadableFragment(html: string): string {
  const cleaned = removeNonContent(html);
  const candidates = [
    ...cleaned.matchAll(/<main\b[^>]*>([\s\S]*?)<\/main>/gi),
    ...cleaned.matchAll(/<article\b[^>]*>([\s\S]*?)<\/article>/gi),
  ]
    .map((match) => match[1] ?? "")
    .filter(Boolean);

  if (candidates.length > 0) {
    return candidates.reduce((longest, candidate) => candidate.length > longest.length ? candidate : longest);
  }

  return cleaned.match(/<body\b[^>]*>([\s\S]*?)<\/body>/i)?.[1] ?? cleaned;
}

function resolveLink(rawUrl: string, baseUrl: string): string | undefined {
  try {
    const url = new URL(decodeEntities(rawUrl.trim()), baseUrl);
    return url.protocol === "http:" || url.protocol === "https:" ? url.href : undefined;
  } catch {
    return undefined;
  }
}

function normalizeWhitespace(value: string): string {
  return value
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/[ \t]{2,}/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function htmlToMarkdown(html: string, baseUrl: string): string {
  let content = chooseReadableFragment(html);
  const protectedBlocks: string[] = [];
  const protect = (value: string): string => {
    const index = protectedBlocks.push(value) - 1;
    return `\u0000PIWEB${index}\u0000`;
  };

  content = content.replace(/<pre\b[^>]*>([\s\S]*?)<\/pre>/gi, (_match, inner: string) => {
    const code = decodeEntities(stripTags(inner)).replace(/^\n+|\n+$/g, "");
    return protect(`\n\n\`\`\`\n${code}\n\`\`\`\n\n`);
  });
  content = content.replace(/<code\b[^>]*>([\s\S]*?)<\/code>/gi, (_match, inner: string) => {
    const code = decodeEntities(stripTags(inner)).replace(/`/g, "\\`").trim();
    return protect(`\`${code}\``);
  });
  content = content.replace(
    /<img\b[^>]*\bsrc=(["'])(.*?)\1[^>]*>/gi,
    (match, _quote: string, source: string) => {
      const url = resolveLink(source, baseUrl);
      if (!url) return "";
      const alt = decodeEntities(match.match(/\balt=(["'])(.*?)\1/i)?.[2] ?? "").trim();
      return `![${alt}](${url})`;
    },
  );
  content = content.replace(
    /<a\b[^>]*\bhref=(["'])(.*?)\1[^>]*>([\s\S]*?)<\/a>/gi,
    (_match, _quote: string, href: string, label: string) => {
      const text = decodeEntities(stripTags(label)).trim();
      const url = resolveLink(href, baseUrl);
      if (!url) return text;
      return `[${text || url}](${url})`;
    },
  );

  for (let level = 6; level >= 1; level -= 1) {
    const heading = new RegExp(`<h${level}\\b[^>]*>([\\s\\S]*?)<\\/h${level}>`, "gi");
    content = content.replace(
      heading,
      (_match, inner: string) => `\n\n${"#".repeat(level)} ${decodeEntities(stripTags(inner)).trim()}\n\n`,
    );
  }

  content = content
    .replace(/<li\b[^>]*>([\s\S]*?)<\/li>/gi, (_match, inner: string) => `\n- ${decodeEntities(stripTags(inner)).trim()}`)
    .replace(
      /<blockquote\b[^>]*>([\s\S]*?)<\/blockquote>/gi,
      (_match, inner: string) =>
        `\n\n${decodeEntities(stripTags(inner)).trim().split(/\r?\n/).map((line) => `> ${line}`).join("\n")}\n\n`,
    )
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|section|article|main|ul|ol|table|tr)>/gi, "\n\n")
    .replace(/<(p|div|section|article|main|ul|ol|table|tr)\b[^>]*>/gi, "\n");

  content = decodeEntities(stripTags(content));
  content = normalizeWhitespace(content);

  return protectedBlocks.reduce(
    (result, block, index) => result.replaceAll(`\u0000PIWEB${index}\u0000`, block),
    content,
  ).replace(/\n{3,}/g, "\n\n").trim();
}

export function htmlToText(html: string, baseUrl: string): string {
  return htmlToMarkdown(html, baseUrl)
    .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, "$1 ($2)")
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1 ($2)")
    .replace(/^#{1,6}\s+/gm, "")
    .replace(/^>\s?/gm, "")
    .replace(/^\s*[-*]\s+/gm, "• ")
    .replace(/```(?:\w+)?\n([\s\S]*?)```/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .trim();
}
