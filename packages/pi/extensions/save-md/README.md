# Save Markdown

`/save-md path/name` saves the latest completed assistant text response as a
Markdown file.

Safety properties:

- thinking and tool-call blocks are excluded;
- aborted and error responses are skipped;
- destinations must be relative and remain inside the current workspace,
  including after resolving the destination parent;
- parent directories must already exist;
- files are created atomically with exclusive-create semantics and mode `0600`;
- existing files are never overwritten.
