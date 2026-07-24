# Pi web tools

Design starting point inspired by Dylan Mulroy's [Pi web-tools extension](https://github.com/dmmulroy/.dotfiles/tree/main/home/.pi/agent/extensions/web-tools); this implementation is independently written for the dsqr Nix/XDG setup.

Two global, model-callable tools:

- `websearch` searches the current public web through Exa's hosted MCP endpoint.
- `webfetch` reads one public URL as Markdown, text, raw HTML, or an inline raster image.

The intended flow is `websearch` → select an authoritative result → `webfetch`.

## Enablement

The package declares `web-tools` as enabled by default. It can still be controlled per Home Manager configuration:

```nix
programs.pi.extensions.web-tools.enable = true;
```

Home Manager links the complete package into
`$PI_CODING_AGENT_DIR/extensions/web-tools`, including its locked runtime
dependencies. Pi discovers `index.ts` from that directory.

## Behavior

| Capability | Implementation |
| --- | --- |
| Search transport | Official `https://mcp.exa.ai/mcp` JSON-RPC/MCP endpoint |
| Search response formats | JSON and SSE |
| Search modes | `auto`, `fast`, plus `deep` as a compatibility alias for `fast` |
| Search results | Normalized title, public URL, date/source/score when present, and a short snippet |
| Fetch formats | Markdown, plain text, raw HTML, PNG/JPEG/GIF/WebP |
| HTML extraction | DOM-based content selection, boilerplate removal, GFM tables, absolute links and images |
| Browser compatibility | Browser-like headers and a narrow Cloudflare-challenge user-agent retry |
| Output handling | 50 KiB or 2,000-line context cap, with complete overflow in a private temporary file |
| Pi UI | Custom progress, compact success/error metadata, and Ctrl+O previews |
| Errors | Stable, credential-free boundary messages for timeouts, HTTP errors, unsupported content, and provider failures |

This uses Exa's public hosted MCP endpoint directly. It does not depend on
Dylan's private Cloudflare hostname and it is not an MCP proxy that this repo
operates. Exa search and an `executor` extension are separate concerns:
websearch finds public sources; an executor delegates or runs agent work.

## Safety

- Only HTTP and HTTPS URLs are accepted.
- URL credentials, localhost, private addresses, link-local addresses, reserved ranges, and unsafe redirect destinations are blocked.
- DNS results are validated and the connection is pinned to the validated public address to prevent DNS rebinding.
- Fetches time out after 30 seconds by default and allow at most five redirects.
- Responses are limited to 5 MB.
- Tool text is limited to 50 KB or 2,000 lines; complete truncated output is saved to a temporary file.
- Search responses are limited to 1 MB and searches time out after 25 seconds.
- URL user info and common credential-like query parameters are masked in progress, details, result text, and custom rendering.
- Tool instructions tell the model to treat all retrieved content as untrusted data.

Pi tool-call arguments are persisted by Pi before an extension executes. The
extension therefore rejects credential-bearing URLs and masks every projection
it controls, but it cannot retroactively remove a secret already placed in a
tool call. General file/tool-result cloaking belongs in a separate extension.

## Source map

| File | Responsibility |
| --- | --- |
| `index.ts` | Pi tool registration, input schemas, orchestration, and result projection |
| `network.ts` | Public URL validation, DNS pinning, redirects, limits, cancellation, and HTTP |
| `html.ts` | DOM readability extraction and Markdown/text conversion |
| `providers/exa.ts` | Exa HTTP adapter and provider boundary |
| `providers/exa-protocol.ts` | MCP request encoding and JSON/SSE parsing |
| `providers/exa-results.ts` | Exa text normalization and concise rendering |
| `redaction.ts` | Non-serializing secret wrapper and URL display redaction |
| `output.ts` | Context bounds and private temporary overflow files |
| `render.ts` | Pi collapsed and expanded terminal UI |
| `settings.ts` | Central defaults and supported modes |
| `test/*.test.ts` | Security, protocol, conversion, truncation, and redaction regressions |
| `package.json` / `package-lock.json` | Reproducible HTML conversion dependencies |

The Nix build runs the strict TypeScript check and the complete focused test
suite before building Pi, so a broken extension cannot produce the Pi package.
