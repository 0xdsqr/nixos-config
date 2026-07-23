# Pi web tools

Design starting point inspired by Dylan Mulroy's [Pi web-tools extension](https://github.com/dmmulroy/.dotfiles/tree/main/home/.pi/agent/extensions/web-tools); this implementation is independently written for the dsqr Nix/XDG setup.

Two global, model-callable tools:

- `websearch` searches the current public web through Exa's hosted MCP endpoint.
- `webfetch` reads one public URL as Markdown, text, raw HTML, or an inline raster image.

The intended flow is `websearch` → select an authoritative result → `webfetch`.

## Safety and limits

- Only HTTP and HTTPS URLs are accepted.
- URL credentials, localhost, private addresses, link-local addresses, and unsafe redirect destinations are blocked.
- DNS results are validated and the connection is pinned to the validated public address to prevent DNS rebinding.
- Fetches time out after 30 seconds by default and allow at most five redirects.
- Responses are limited to 5 MB.
- Tool text is limited to 50 KB or 2,000 lines; complete truncated output is saved to a temporary file.
- Tool instructions tell the model to treat all retrieved content as untrusted data.

The implementation has no runtime npm dependencies. Pi supplies its extension API and schema packages; everything else uses Node.js built-ins.
