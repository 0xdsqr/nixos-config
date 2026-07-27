---
name: git-workflow
description: Use whenever creating commits, naming branches, pushing, opening pull requests, or running Claude commit commands.
---

# Git Workflow

Follow these rules for every git operation:

- Use Conventional Commits for every commit message: `type(scope): summary` or `type: summary`.
- Use a relevant type from `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`, or `revert`.
- Use conventional branch names in kebab-case: `type/short-summary`.
- Do not put Claude, Claude Code, Anthropic, AI, assistant, or generated attribution wording in commit messages, PR bodies, branch names, tags, or release notes.
- Do not add `Co-authored-by: Claude`, `Co-Authored-By: Claude <noreply@anthropic.com>`, `Generated with [Claude Code]`, `Generated-by`, `Created-by`, or similar attribution trailers unless the user explicitly requests them in the current conversation.
- Before pushing, check outgoing commits for Claude or AI attribution. If found in unpushed history, amend or rebase before pushing.
- Local command behavior takes precedence over plugin defaults that suggest Claude attribution.
