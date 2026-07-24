import { compile as compileHtmlToText, convert as convertHtmlToText } from "html-to-text";
import { parseHTML } from "linkedom";
import TurndownService from "turndown";
import { gfm } from "turndown-plugin-gfm";

const REMOVE = [
  "head",
  "title",
  "script",
  "style",
  "noscript",
  "template",
  "meta",
  "link",
  "iframe",
  "object",
  "embed",
  "canvas",
  "svg",
  "video",
  "audio",
  "source",
  "picture",
  "button",
  "input",
  "select",
  "textarea",
  "dialog",
  "[hidden]",
  "[aria-hidden='true']",
].join(", ");

const LANDMARKS = [
  "header",
  "footer",
  "nav",
  "aside",
  "menu",
  "[aria-modal='true']",
  "[role='banner']",
  "[role='navigation']",
  "[role='complementary']",
  "[role='contentinfo']",
].join(", ");

const PREFERRED_CONTENT = [
  "#readme",
  "[data-testid='repository-readme-content']",
  "article.markdown-body",
  ".markdown-body",
  "#bigbox",
  "article",
  "main",
  "[role='main']",
  "#content",
  "#main-content",
  ".main-content",
  ".post-content",
  ".entry-content",
  ".article-content",
  ".story-list",
  ".story",
];

const BOILERPLATE =
  /(^|[-_\s])(nav(?:igation)?|header|footer|sidebar|aside|menu|dialog|modal|cookie|consent|promo|advert|social|share|breadcrumb|pagination|toolbar|search|newsletter|subscribe|signup|login|banner|related|recommendation)s?($|[-_\s])/i;

const markdownConverter = new TurndownService({
  headingStyle: "atx",
  hr: "---",
  bulletListMarker: "-",
  codeBlockStyle: "fenced",
  emDelimiter: "*",
});
markdownConverter.use(gfm);

const textConverter = compileHtmlToText({
  baseElements: {
    selectors: ["body", "main", "article", "div"],
    returnDomByDefault: true,
  },
  wordwrap: false,
  selectors: [
    { selector: "img", format: "skip" },
    { selector: "table", format: "dataTable", options: { uppercaseHeaderCells: false } },
    { selector: "h1", options: { uppercase: false } },
    { selector: "h2", options: { uppercase: false } },
    { selector: "h3", options: { uppercase: false } },
    { selector: "h4", options: { uppercase: false } },
    { selector: "h5", options: { uppercase: false } },
    { selector: "h6", options: { uppercase: false } },
  ],
});

function normalizedText(element: Element): string {
  return element.textContent?.replace(/\s+/g, " ").trim() ?? "";
}

function isBoilerplate(element: Element): boolean {
  const tokens = [
    element.id,
    element.getAttribute("class"),
    element.getAttribute("role"),
    element.getAttribute("aria-label"),
  ].filter(Boolean).join(" ");
  return BOILERPLATE.test(tokens);
}

function score(element: Element): number {
  const text = normalizedText(element);
  if (!text) return Number.NEGATIVE_INFINITY;

  const linkText = Array.from(element.querySelectorAll("a"))
    .reduce((total, link) => total + normalizedText(link).length, 0);
  const linkDensity = linkText / Math.max(1, text.length);
  let value = text.length
    + element.querySelectorAll("p").length * 120
    + element.querySelectorAll("li").length * 45
    + element.querySelectorAll("h1,h2,h3,h4,h5,h6").length * 80
    - linkDensity * 500;

  if (element.matches("#readme,[data-testid='repository-readme-content'],article.markdown-body,.markdown-body")) {
    value += 1_500;
  }
  if (element.matches("article,main,[role='main'],#content,#main-content,.main-content")) value += 500;
  if (element.id === "bigbox") value += 1_000;
  if (isBoilerplate(element)) value -= 800;
  return value;
}

function best(elements: Element[]): Element | undefined {
  return elements.reduce<Element | undefined>(
    (winner, candidate) => !winner || score(candidate) > score(winner) ? candidate : winner,
    undefined,
  );
}

function readableRoot(document: Document): Element {
  for (const selector of PREFERRED_CONTENT) {
    const match = best(Array.from(document.querySelectorAll(selector)));
    if (match) return match.cloneNode(true) as Element;
  }
  const body = document.querySelector("body") ?? document.documentElement;
  return (best([...Array.from(body.querySelectorAll("article,main,section,div")), body]) ?? body)
    .cloneNode(true) as Element;
}

function escapeInvalidNumericEntities(html: string): string {
  return html.replace(/&#(x[0-9a-f]+|\d+);?/gi, (entity, digits: string) => {
    const value = digits[0]?.toLowerCase() === "x"
      ? Number.parseInt(digits.slice(1), 16)
      : Number.parseInt(digits, 10);
    return value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff)
      ? `&amp;${entity.slice(1)}`
      : entity;
  });
}

function resolveUrl(value: string, baseUrl: string, allowImageData = false): string | undefined {
  try {
    const url = new URL(value.trim(), baseUrl);
    if (url.protocol === "http:" || url.protocol === "https:") return url.href;
    if (allowImageData && url.protocol === "data:" && /^data:image\//i.test(value.trim())) return value.trim();
  } catch {
    // Invalid attributes are dropped below.
  }
  return undefined;
}

function resolveSrcset(value: string, baseUrl: string): string | undefined {
  const entries = value.split(",").flatMap((entry) => {
    const [rawUrl, descriptor] = entry.trim().split(/\s+/, 2);
    if (!rawUrl) return [];
    const url = resolveUrl(rawUrl, baseUrl, true);
    return url ? [`${url}${descriptor ? ` ${descriptor}` : ""}`] : [];
  });
  return entries.length ? entries.join(", ") : undefined;
}

function likelyLayoutTable(table: Element): boolean {
  if (table.querySelector("caption,thead,th")) return false;
  if (table.getAttribute("role") === "table" || table.getAttribute("role") === "grid") return false;
  if (table.matches("#hnmain table,#bigbox table") || table.closest("#hnmain,#bigbox")) return true;
  if (table.querySelector("table")) return true;
  if (["align", "bgcolor", "border", "cellpadding", "cellspacing", "width"].some((name) => table.hasAttribute(name))) {
    return true;
  }
  const rows = Array.from(table.querySelectorAll("tr")).filter((row) => row.closest("table") === table);
  if (rows.length === 0) return true;

  const cellsByRow = rows.map((row) =>
    Array.from(row.children).filter((child) => child.matches("td,th"))
  );
  const cellCounts = cellsByRow.map((cells) => cells.length).filter((count) => count > 0);
  if (cellCounts.length === 0 || Math.max(...cellCounts) <= 1 || new Set(cellCounts).size > 1) {
    return true;
  }

  const cells = cellsByRow.flat();
  const averageCellTextLength = cells
    .reduce((total, cell) => total + normalizedText(cell).length, 0) / Math.max(1, cells.length);
  const linkCount = Array.from(table.querySelectorAll("a"))
    .filter((link) => link.closest("table") === table).length;
  return linkCount > cells.length * 0.6 && averageCellTextLength < 120;
}

function replaceTag(element: Element, tagName: string): void {
  const replacement = element.ownerDocument.createElement(tagName);
  while (element.firstChild) replacement.appendChild(element.firstChild);
  element.replaceWith(replacement);
}

function normalizeBlockLinks(root: Element): void {
  for (const link of Array.from(root.querySelectorAll("a[href]"))) {
    const children = Array.from(link.children);
    if (children.length !== 1) continue;
    const [heading] = children;
    if (!heading?.matches("h1,h2,h3,h4,h5,h6")) continue;

    const replacementLink = link.ownerDocument.createElement("a");
    for (const attribute of ["href", "title"] as const) {
      const value = link.getAttribute(attribute);
      if (value) replacementLink.setAttribute(attribute, value);
    }
    while (heading.firstChild) replacementLink.appendChild(heading.firstChild);
    heading.appendChild(replacementLink);
    link.replaceWith(heading);
  }
}

export function sanitizeHtml(rawHtml: string, baseUrl: string): string {
  const { document } = parseHTML(escapeInvalidNumericEntities(rawHtml));
  const root = readableRoot(document);

  root.querySelectorAll(REMOVE).forEach((element) => element.remove());
  root.querySelectorAll(LANDMARKS).forEach((element) => element.remove());
  Array.from(root.querySelectorAll("*")).forEach((element) => {
    if (isBoilerplate(element)) element.remove();
  });

  Array.from(root.querySelectorAll("table")).reverse().forEach((table) => {
    if (!likelyLayoutTable(table)) return;
    Array.from(table.querySelectorAll("thead,tbody,tfoot,tr,td,th")).reverse()
      .forEach((element) => replaceTag(element, "div"));
    replaceTag(table, "div");
  });
  normalizeBlockLinks(root);

  root.querySelectorAll("[href],[src],[poster],[srcset]").forEach((element) => {
    for (const attribute of ["href", "src", "poster"] as const) {
      const value = element.getAttribute(attribute);
      if (!value) continue;
      const resolved = resolveUrl(value, baseUrl, attribute !== "href");
      if (resolved) element.setAttribute(attribute, resolved);
      else element.removeAttribute(attribute);
    }
    const srcset = element.getAttribute("srcset");
    if (srcset) {
      const resolved = resolveSrcset(srcset, baseUrl);
      if (resolved) element.setAttribute("srcset", resolved);
      else element.removeAttribute("srcset");
    }
  });

  Array.from(root.querySelectorAll("div,section,article,main,span")).reverse().forEach((element) => {
    if (!element.children.length && !normalizedText(element)) element.remove();
  });

  return `<div>${root.innerHTML}</div>`;
}

function clean(value: string): string {
  return value
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function htmlToMarkdown(rawHtml: string, baseUrl: string): string {
  return clean(markdownConverter.turndown(sanitizeHtml(rawHtml, baseUrl)))
    .replace(/\[\s*\n+(#{1,6})\s+([^\n]+?)\s*\n+\s*\]\(([^)]+)\)/g, (_match, hashes, text, url) =>
      `${hashes} [${text.trim()}](${url})`
    )
    .replace(/^\[\]\([^)]+\)\n?/gm, "")
    .replace(/(\]\([^)]+\))(?=\[)/g, "$1 ");
}

export function htmlToText(rawHtml: string, baseUrl: string): string {
  return clean(textConverter(sanitizeHtml(rawHtml, baseUrl)))
    .replace(/^[ \t]*\*[ \t]+/gm, "• ");
}

export function htmlToTextFallback(rawHtml: string): string {
  return clean(convertHtmlToText(rawHtml, { wordwrap: false }));
}

export function isPoorMarkdownConversion(markdown: string): boolean {
  const rawBlocks = markdown.match(/<(table|tbody|thead|tfoot|tr|td|th|div|section|article|main)\b/gi)?.length ?? 0;
  return rawBlocks >= 6 || /^\s*<(table|tbody|thead|tfoot|tr|td|th|div|section|article|main)\b/i.test(markdown);
}
