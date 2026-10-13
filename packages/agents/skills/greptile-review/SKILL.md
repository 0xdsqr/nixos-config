---
name: greptile-review
description: Drive a GitHub pull request or GitLab merge request through Greptile review until it reaches a target confidence score (default 5/5). Use when the user asks to run the Greptile loop, get Greptile to 5/5, or push and address Greptile review comments.
---

# Greptile Review Loop

Push the current work, then repeat review → triage → fix until Greptile's
confidence score reaches the target or the round limit is hit.

`scripts/greptile` (in this skill's directory) wraps the forge APIs. It detects
GitHub or GitLab from `origin` and the PR/MR from the current branch, and every
command prints JSON:

| Command | Purpose |
| --- | --- |
| `status` | Latest summary: `score` (0–5 or null), `summary_at`, `summary` text, `notice` |
| `threads` | Unresolved Greptile threads: `id`, `path`, `line`, `body` |
| `reply ID TEXT` | Reply inside a thread |
| `resolve ID` | Resolve a thread |
| `retrigger` | Ask Greptile for a new review; returns `requested_at` |
| `wait SINCE` | Block until a summary newer than `SINCE` exists, then print `status` |

## Settings

Take these from the user's request, otherwise use the defaults:

- Target score: `5`
- Maximum review rounds: `5`
- Wait timeout per round: `GREPTILE_WAIT_TIMEOUT` seconds (default `1200`)
- Trigger comment: `GREPTILE_TRIGGER` (default `@greptileai` on GitHub,
  `@greptile review` on GitLab)

## Workflow

1. Confirm the branch is not the default branch and that a PR/MR exists. If
   none exists, open one with `gh pr create` or `glab mr create` following the
   repository's conventions.
2. Commit pending work with a Conventional Commit message and push. Follow the
   repository's git rules; never force-push unless the user asked.
3. Run `greptile retrigger`, then `greptile wait <requested_at>`. Keep the
   returned status as this round's result.
4. Stop and report if `notice` is set (credit limit, reviews disabled) or the
   wait times out.
5. If `score` is at or above the target and `greptile threads` is empty, stop:
   the loop succeeded.
6. Triage every unresolved thread, plus any issue the `summary` lists that has
   no thread (for example comments outside the diff). Read the referenced code
   before judging. For each one decide:
   - **Valid**: the problem is real for this change. Fix it.
   - **Invalid**: it is wrong, already handled, or out of scope. Do not change
     code for it.
7. Commit the fixes (Conventional Commits, one focused commit per round is
   fine) and push.
8. For every thread, `greptile reply` with the verdict and a one or two
   sentence reason, starting with `Valid:` or `Invalid:`. For valid ones, name
   the commit that fixes it. Then `greptile resolve` the thread. Never resolve
   a thread without replying first.
9. Go back to step 3. Count rounds; when the maximum is reached without hitting
   the target, stop.

## Report

End with: rounds used, final score, each thread's verdict (valid or invalid)
with its reason, the commits pushed, and anything left open or needing the
user's judgment.
