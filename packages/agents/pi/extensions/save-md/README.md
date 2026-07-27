# Save Markdown

`/save-md path/name` saves the latest completed assistant text response as a
Markdown file in the current workspace.

`/save-md --library path/name` (or `/save-md -l path/name`) saves it in Pi's
private document library:

- macOS: `~/Documents/Pi`
- Linux: `$XDG_DOCUMENTS_DIR/Pi`, falling back to `~/Documents/Pi`

The library is created on first use. To use another absolute location, set:

```nix
programs.pi.extensions.save-md.settings.libraryDirectory = "/path/to/Pi";
```

`~/path` is also accepted in the generated `save-md.json` configuration.

Safety properties:

- thinking and tool-call blocks are excluded;
- aborted and error responses are skipped;
- destinations must be relative and remain inside the current workspace,
  including after resolving the destination parent;
- parent directories must already exist;
- files are created atomically with exclusive-create semantics and mode `0600`;
- existing files are never overwritten;
- the private library is mode `0700`, must be owned by the current user, and
  cannot itself be a symlink.
