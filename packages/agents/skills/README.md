# Agent skills

This directory is the canonical catalog for skills managed by Home Manager.
Catalog entries are unavailable until a host assigns one or more targets through
`dsqr.home.agentSkills.<name>.targets`.

Targets:

- `agents`: links into `~/.agents/skills` for Codex and Pi
- `claude`: links into Claude Code's XDG and compatibility skill directories
- `pi`: links into Pi's XDG agent directory without exposing the skill to Codex

Local skills live beside `default.nix`. External skills use locked flake inputs;
refresh those inputs with `nix run .#update-pins -- skills`.
