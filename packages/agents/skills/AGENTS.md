# Skill catalog instructions

These rules apply to every skill under this directory.

## Add a local skill

1. Copy `_template` to a lowercase, hyphenated directory whose name matches the
   skill name.
2. Remove the `.template` suffix from `SKILL.md.template` and
   `agents/openai.yaml.template`.
3. Replace every placeholder. Keep `SKILL.md` focused on the workflow and put
   trigger phrases in its frontmatter description.
4. Add `scripts/`, `references/`, or `assets/` only when the skill actually
   needs them. Do not add a README inside an individual skill.
5. Register the directory in `default.nix`. Registration makes the skill
   available as an opt-in Home Manager option; it does not enable it on a host.
6. Select targets in the host:

   - `agents`: shared root for Codex, Pi, and OpenCode
   - `claude`: Claude Code-only XDG root
   - `codex`: Codex-only XDG root
   - `opencode`: OpenCode-only XDG root
   - `pi`: Pi-only XDG root

7. Validate the skill with the available Agent Skills validator, format the
   repository, and evaluate or build every host changed by the opt-in.

## Invocation policy

New skills should be manual-only unless the user explicitly wants automatic
discovery. For Codex, keep `policy.allow_implicit_invocation: false` in
`agents/openai.yaml`. If another runtime supports its own manual-invocation
frontmatter, add that setting only after checking the runtime's current schema.

## External skills

Add external repositories as locked flake inputs and register only the exact
skill subdirectory. Review the fetched `SKILL.md` and any bundled scripts before
enabling it. Update external skill inputs with:

```sh
nix run .#update-pins -- skills
```
