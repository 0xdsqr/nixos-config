import assert from "node:assert/strict";
import test from "node:test";

import { htmlToMarkdown, htmlToText, isPoorMarkdownConversion } from "../html.ts";

test("htmlToMarkdown extracts readable content and resolves links", () => {
  const html = `
    <html>
      <body>
        <nav>Ignore navigation</nav>
        <main>
          <h1>Useful &amp; calm</h1>
          <p>Read <a href="/docs">the docs</a>.</p>
          <pre><code>const answer = 42;</code></pre>
          <script>ignore()</script>
        </main>
      </body>
    </html>
  `;

  const markdown = htmlToMarkdown(html, "https://example.com/start");
  assert.match(markdown, /^# Useful & calm/m);
  assert.match(markdown, /\[the docs\]\(https:\/\/example\.com\/docs\)/);
  assert.match(markdown, /```\nconst answer = 42;\n```/);
  assert.doesNotMatch(markdown, /navigation|ignore/);
});

test("htmlToText removes markdown syntax", () => {
  const text = htmlToText("<main><h2>Hello</h2><ul><li>One</li></ul></main>", "https://example.com");
  assert.equal(text, "Hello\n\n• One");
});

test("invalid numeric entities remain harmless text", () => {
  assert.equal(htmlToMarkdown("<main>&#99999999;</main>", "https://example.com"), "&#99999999;");
});

test("markdown conversion keeps data tables while flattening layout tables", () => {
  const html = `
    <main>
      <table><thead><tr><th>Name</th><th>Value</th></tr></thead>
        <tbody><tr><td>Moon</td><td>Purple</td></tr></tbody></table>
      <table width="100%"><tr><td><h2>Layout content</h2></td></tr></table>
    </main>
  `;
  const markdown = htmlToMarkdown(html, "https://example.com");
  assert.match(markdown, /\| Name\s+\| Value\s+\|/);
  assert.match(markdown, /## Layout content/);
});

test("boilerplate is removed and relative image attributes are resolved", () => {
  const markdown = htmlToMarkdown(
    `<main><div class="cookie-banner">Accept everything</div>
      <article><h1>Post</h1><img alt="Moon" src="/moon.png"></article></main>`,
    "https://example.com/posts/one",
  );
  assert.doesNotMatch(markdown, /Accept everything/);
  assert.match(markdown, /!\[Moon\]\(https:\/\/example\.com\/moon\.png\)/);
});

test("skipped elements do not remove adjacent text or leak document metadata", () => {
  const html = `
    <html>
      <head><title>Private title</title><meta name="secret" content="nope"></head>
      <body>start<script>ignore()</script>tail<p>end</p></body>
    </html>
  `;
  assert.equal(htmlToText(html, "https://example.com/page"), "starttail\n\nend");
  assert.doesNotMatch(htmlToMarkdown(html, "https://example.com/page"), /Private title|secret|ignore/);
});

test("text conversion preserves block boundaries", () => {
  const html = "<main><div>one</div><div>two</div><p>three <span>four</span></p><p>five</p></main>";
  assert.equal(htmlToText(html, "https://example.com"), "one\ntwo\n\nthree four\n\nfive");
});

test("heading links are normalized into valid linked Markdown headings", () => {
  const markdown = htmlToMarkdown(
    `<main><a href="/story"><h2>Story title</h2></a></main>`,
    "https://example.com/",
  );
  assert.equal(markdown, "## [Story title](https://example.com/story)");
});

test("news-style layout tables are flattened without losing their content", () => {
  const markdown = htmlToMarkdown(
    `<div id="bigbox"><table><tbody>
      <tr><td>1.</td><td><a href="/item">Item title</a></td></tr>
      <tr><td></td><td>123 points by alice</td></tr>
    </tbody></table></div>`,
    "https://news.ycombinator.com/",
  );
  assert.match(markdown, /Item title/);
  assert.match(markdown, /123 points by alice/);
  assert.doesNotMatch(markdown, /<table|<tr|<td/i);
  assert.equal(isPoorMarkdownConversion(markdown), false);
});
