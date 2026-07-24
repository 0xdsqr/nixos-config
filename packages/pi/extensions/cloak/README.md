# Cloak

Cloak redacts secrets from final Pi tool-result text before that result enters
the model context and session history.

Default coverage includes:

- all assignment values from `.env*`, `.envrc*`, `.direnv`, local Nix, and
  secret-named Nix files;
- complete contents of private-key, credential, age, and common structured
  secret files;
- sensitive key/value assignments in arbitrary output;
- private-key blocks, age secret keys, GitHub/OpenAI-style tokens, AWS access
  IDs, JWTs, authorization headers, URL passwords, and secret query parameters;
- `read`, `grep`, `bash`, and custom tool results because detection is applied
  to every final text result.

The Nix-managed configuration is written to
`$PI_CODING_AGENT_DIR/cloak.json`. Add exact local rules or organization token
formats through `programs.pi.extensions.cloak.settings`:

```nix
programs.pi.extensions.cloak.settings = {
  enabled = true;
  mask = "[REDACTED]";
  rules = [
    {
      files = [ "**/private-config.nix" ];
      mode = "assignments";
    }
  ];
  patterns = [
    {
      pattern = "company_[A-Za-z0-9]{24,}";
      flags = "i";
    }
  ];
};
```

Use `/cloak-status` for counters and `/cloak-reload` after changing a
non-Nix-managed configuration.

## Boundary

Cloak protects final textual tool results. It cannot retroactively remove a
secret already placed in a model tool-call argument or user message, and Pi
does not expose a post-result hook for user `!` shell commands. Avoid placing
credentials in prompts or command arguments; prefer environment injection,
agenix/sops, and `!!` for user shell output that must be excluded from model
context.
