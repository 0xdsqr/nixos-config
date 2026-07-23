import assert from "node:assert/strict";
import test from "node:test";

import { htmlToMarkdown, htmlToText } from "../html.ts";

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
  assert.equal(text, "Hello\n• One");
});

test("invalid numeric entities remain harmless text", () => {
  assert.equal(htmlToMarkdown("<main>&#99999999;</main>", "https://example.com"), "&#99999999;");
});
