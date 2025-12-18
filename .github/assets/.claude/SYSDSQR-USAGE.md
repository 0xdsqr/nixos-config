# sysdsqr CLI Usage Guide

This guide shows you how to use the `sysdsqr` CLI tool with Nix in various scenarios.

## What is sysdsqr?

`sysdsqr` is a system administration CLI tool for managing your homelab, built with Bun and packaged with Nix. It compiles to a single standalone binary.

## Understanding Nix Apps vs Packages

The flake exposes `sysdsqr` as both a **package** and an **app**:

**Package** (`packages.${system}.sysdsqr`):
- Built binary in `/nix/store`
- Use with: `nix build .#sysdsqr`
- Result: `./result/bin/sysdsqr`

**App** (`apps.${system}.sysdsqr`):
- Runnable application wrapper around the package
- Use with: `nix run .#sysdsqr`
- Automatically builds then executes

**Why both?**
- Apps make `nix run` work seamlessly
- Packages let you install or reference the binary
- Best practice: expose both (we do!)

---

## Usage Scenarios

### 1. Local Development (From Repository Root)

When you're developing `sysdsqr` from this repository:

#### Using `nix run`

```bash
# Explicit: Run sysdsqr (recommended when adding more apps)
nix run .#sysdsqr

# With arguments (MUST use .#sysdsqr before --)
nix run .#sysdsqr -- hello

# Shorthand: Uses default app (currently sysdsqr)
nix run .
# Output: hello world

# WARNING: This does NOT work (trying to pass args to default):
# nix run . -- hello     # Wrong
# nix run -- hello       # Also wrong
# Always be explicit when passing arguments:
nix run .#sysdsqr -- hello  # Correct
```

**Why be explicit?** When you add more apps later (e.g., `sysdsqr-server`), being explicit avoids confusion.

#### Using `nix build` then execute

```bash
# Build the package
nix build .#sysdsqr

# Run the binary
./result/bin/sysdsqr
./result/bin/sysdsqr hello
```

#### Development workflow

```bash
# Make changes to pkgs/sysdsqr-cli/index.ts
vim pkgs/sysdsqr-cli/index.ts

# Test with Bun directly (fastest)
cd pkgs/sysdsqr-cli
bun run index.ts
bun run index.ts hello

# Test with Nix build
cd ../..  # back to root
nix build .#sysdsqr --rebuild
./result/bin/sysdsqr
```

---

### 2. Using from GitHub (No Local Clone)

Run directly from GitHub without cloning:

```bash
# Run from GitHub main branch
nix run github:0xdsqr/nixos-config#sysdsqr

# With arguments
nix run github:0xdsqr/nixos-config#sysdsqr -- hello

# Run from specific commit
nix run github:0xdsqr/nixos-config/9c6d0d6#sysdsqr

# Run from specific tag/release
nix run github:0xdsqr/nixos-config/v0.1.0#sysdsqr
```

**Note**: The first time you run this, Nix will fetch and build the package. Subsequent runs use the cached build.

---

### 3. Installing to Your System

#### Option A: Install via `nix profile`

```bash
# Install from GitHub
nix profile install github:0xdsqr/nixos-config#sysdsqr

# Now you can run it directly
sysdsqr
sysdsqr hello

# List installed packages
nix profile list

# Update sysdsqr
nix profile upgrade '.*sysdsqr.*'

# Remove sysdsqr
nix profile remove '.*sysdsqr.*'
```

#### Option B: Add to NixOS/Home Manager Configuration

**In your `flake.nix` inputs:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dsqr-nix.url = "github:0xdsqr/nixos-config";
  };
}
```

**In your Home Manager configuration:**

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.dsqr-nix.packages.${pkgs.system}.sysdsqr
  ];
}
```

**Or in NixOS configuration:**

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.dsqr-nix.packages.${pkgs.system}.sysdsqr
  ];
}
```

Then rebuild:

```bash
# For NixOS
sudo nixos-rebuild switch --flake .

# For Home Manager
home-manager switch --flake .

# For nix-darwin
darwin-rebuild switch --flake .
```

---

### 4. Using on Different Machines

#### From Linux x86_64

```bash
nix run github:0xdsqr/nixos-config#sysdsqr
```

#### From Linux ARM64

```bash
nix run github:0xdsqr/nixos-config#sysdsqr
```

#### From macOS Intel

```bash
nix run github:0xdsqr/nixos-config#sysdsqr
```

#### From macOS Apple Silicon

```bash
nix run github:0xdsqr/nixos-config#sysdsqr
```

The flake supports all four platforms and will automatically build for your system.

---

## Troubleshooting

### Issue: "flake does not provide attribute"

**Symptom:**
```
error: flake 'github:0xdsqr/nixos-config' does not provide attribute 'apps.aarch64-darwin.sysdsqr'
```

**Cause:** Nix has cached an old version of the flake from GitHub.

**Solution:** Clear the flake cache and force refresh:

```bash
# Refresh the flake metadata
nix flake metadata github:0xdsqr/nixos-config --refresh

# Or clear all flake cache and try again
rm -rf ~/.cache/nix/fetcher-cache-v1.sqlite*
nix run github:0xdsqr/nixos-config#sysdsqr
```

**Alternative:** Use a specific commit hash:

```bash
# Find the latest commit
git ls-remote https://github.com/0xdsqr/nixos-config HEAD

# Use that commit
nix run github:0xdsqr/nixos-config/COMMIT_HASH#sysdsqr
```

---

### Issue: Build fails with Bun errors

**Symptom:**
```
error: builder for '/nix/store/...-sysdsqr-0.1.0.drv' failed
```

**Solution 1:** Test with Bun directly first:

```bash
cd pkgs/sysdsqr-cli
bun run index.ts
```

If Bun works but Nix fails, it might be a sandboxing issue.

**Solution 2:** Rebuild without cache:

```bash
nix build .#sysdsqr --rebuild
```

**Solution 3:** Check Nix logs:

```bash
nix build .#sysdsqr --print-build-logs
```

---

### Issue: Package not updating after git push

**Symptom:** You pushed changes to GitHub but `nix run github:...` still uses old version.

**Solution:** Force refresh (same as first issue):

```bash
nix flake metadata github:0xdsqr/nixos-config --refresh
nix run github:0xdsqr/nixos-config#sysdsqr
```

---

### Issue: Binary doesn't work on system

**Symptom:**
```
zsh: exec format error: ./result/bin/sysdsqr
```

**Cause:** Binary was built for different architecture.

**Solution:** Build for your specific system:

```bash
# Let Nix detect your system
nix build .#sysdsqr

# Or specify explicitly
nix build .#sysdsqr --system aarch64-darwin  # M1/M2 Mac
nix build .#sysdsqr --system x86_64-darwin   # Intel Mac
nix build .#sysdsqr --system x86_64-linux    # Linux x86_64
nix build .#sysdsqr --system aarch64-linux   # Linux ARM64
```

---

### Issue: Permission denied

**Symptom:**
```
zsh: permission denied: ./result/bin/sysdsqr
```

**Solution:** The binary should already be executable. If not:

```bash
chmod +x ./result/bin/sysdsqr
./result/bin/sysdsqr
```

---

## Quick Reference

### Local Development

| Command | Purpose |
|---------|---------|
| `nix run .#sysdsqr` | Run from local repo |
| `nix build .#sysdsqr` | Build binary to ./result |
| `cd pkgs/sysdsqr-cli && bun run index.ts` | Test without Nix |
| `nix build .#sysdsqr --rebuild` | Force rebuild |

### Remote Usage

| Command | Purpose |
|---------|---------|
| `nix run github:0xdsqr/nixos-config#sysdsqr` | Run from GitHub |
| `nix run github:0xdsqr/nixos-config/TAG#sysdsqr` | Run specific version |
| `nix profile install github:0xdsqr/nixos-config#sysdsqr` | Install to profile |
| `nix flake metadata github:0xdsqr/nixos-config --refresh` | Clear cache |

### Troubleshooting

| Command | Purpose |
|---------|---------|
| `nix flake metadata github:0xdsqr/nixos-config --refresh` | Refresh flake cache |
| `nix build .#sysdsqr --print-build-logs` | Show build logs |
| `nix flake show github:0xdsqr/nixos-config` | See available outputs |
| `nix build .#sysdsqr --rebuild` | Force rebuild without cache |

---

## Integration Examples

### Using in Shell Scripts

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run sysdsqr from GitHub
nix run github:0xdsqr/nixos-config#sysdsqr -- hello
```

### Using in CI/CD

```yaml
# GitHub Actions example
- name: Run sysdsqr
  run: |
    nix run github:0xdsqr/nixos-config#sysdsqr -- hello
```

### Using in Other Flakes

```nix
{
  inputs = {
    sysdsqr.url = "github:0xdsqr/nixos-config";
  };

  outputs = { self, sysdsqr, ... }: {
    # Use in a script
    packages.x86_64-linux.deploy-script = pkgs.writeShellScriptBin "deploy" ''
      ${sysdsqr.packages.x86_64-linux.sysdsqr}/bin/sysdsqr deploy
    '';
  };
}
```

---

## Configuration Location

The sysdsqr CLI is defined at:
- **Source Code**: `pkgs/sysdsqr-cli/index.ts`
- **Nix Package**: `pkgs/sysdsqr-cli/default.nix`
- **Flake Outputs**: `flake.nix` (lines 165-179)

To modify the CLI:
1. Edit `pkgs/sysdsqr-cli/index.ts`
2. Test with `bun run index.ts`
3. Build with `nix build .#sysdsqr`
4. Commit and push to GitHub

---

## Current Commands

As of version 0.1.0, `sysdsqr` supports:

| Command | Output |
|---------|--------|
| `sysdsqr` | "hello world" |
| `sysdsqr hello` | "world" |

More commands will be added as the tool evolves.

---

## Next Steps

- See [TODO.md](../../../pkgs/sysdsqr-cli/TODO.md) for future plans (if not gitignored)
- See [NIX-COMMANDS.md](./NIX-COMMANDS.md) for general Nix flake commands
- Contribute by adding new commands to `index.ts`
