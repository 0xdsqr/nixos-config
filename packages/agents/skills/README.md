# Agent skills

This directory is the canonical catalog for skills managed by Home Manager.
Catalog entries are unavailable until a host assigns one or more targets through
`dsqr.home.agentSkills.<name>.targets`.

Targets:

- `agents`: links into the shared `~/.agents/skills` root discovered by Codex,
  Pi, and OpenCode
- `claude`: links into Claude Code's XDG skill directory
- `codex`: links into Codex's XDG skill directory
- `opencode`: links into OpenCode's XDG skill directory without exposing the
  skill through the shared root
- `pi`: links into Pi's XDG agent directory without exposing the skill to Codex

Local skills live beside `default.nix`. External skills use locked flake inputs;
refresh those inputs with `nix run .#update-pins -- skills`.

Copy `_template`, remove the `.template` suffixes, and follow `AGENTS.md` when
adding a local skill. The template itself is intentionally absent from
`default.nix`, so no runtime can discover it.
