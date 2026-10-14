<div align="center">
<p align="center">
  <a href="https://github.com/0xdsqr/nixos-config/actions/workflows/check.yml"><img src="https://img.shields.io/github/actions/workflow/status/0xdsqr/nixos-config/check.yml?branch=master&style=for-the-badge&logo=github&label=check" alt="check"></a>
  <a href="https://github.com/0xdsqr/nixos-config/commits/master"><img src="https://img.shields.io/github/last-commit/0xdsqr/nixos-config?style=for-the-badge" alt="last commit"></a>
  <a href="https://wiki.nixos.org/wiki/Flakes"><img src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge" alt="Nix Flakes Ready"></a>
  <a href="#"><img src="https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/nix--darwin-5277C3?style=for-the-badge&logo=apple&logoColor=white" alt="nix-darwin"></a>
</p>

This is my nixos-config. There are many like it, but this one is mine.
</div>

## Deferred Phase 19 — Nix validation and checks cleanup

The top-level ad hoc `tests/` suite was retired on October 14, 2026 at the
owner's request. This removes regression coverage; it is not evidence that the
covered behavior was unimportant. Runtime configurations were not changed.
The existing kubelet decoder check retains its fixture in `checks/fixtures/`.
Package-local tests and the current `checks/` suite remain in place.

The CI `check` workflow builds `checks.x86_64-linux` directly and runs
`nix flake check` on the ARM systems; it did not invoke the retired JavaScript
suite, so no workflow step was removed. The supported Nix
interface is `checks.<system>.<name>` derivations, not a mandatory directory name.
See the [Nix flake check reference](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake-check.html).

Phase 19 follows the existing phases 10–18 without renumbering them:

- Inventory current checks, supported systems, runtime dependencies and CI cost.
- Add focused, reproducible checks through the existing flake-parts `checks/`
  module: evaluated configuration invariants and native configuration validators.
- Prioritize encryption/backup safeguards, firewall and scheduling invariants,
  certificate readiness, telemetry mTLS authorization, and alert-rule behavior.
- Use isolated NixOS VM/service integration checks where behavior cannot be
  established by evaluation or native validation; do not depend on live hosts,
  production credentials, or silently skipped optional binaries.
- Verify actual execution on the supported CI systems, with explicit platform
  limits. Preserve useful package-local tests rather than deleting by filename.

Recovery copy of all 24 former files, including uncommitted versions:
`/private/tmp/nixos-tests-retired.m0HGY4/tests-before-removal.tar.gz` (local,
temporary; not a durable backup). Previously committed files also remain in Git.
