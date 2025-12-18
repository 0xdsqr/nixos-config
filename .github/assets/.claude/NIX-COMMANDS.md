# Essential Nix Flake Commands

A practical reference for Nix flake commands you'll actually use, focused on modern flake-style operations.

## Table of Contents

1. [Flake Management](#flake-management)
2. [Cache Management](#cache-management)
3. [Garbage Collection](#garbage-collection)
4. [Building & Running](#building--running)
5. [Debugging](#debugging)
6. [System Management](#system-management)

---

## Flake Management

### Inspecting Flakes

| Command | Purpose |
|---------|---------|
| `nix flake show` | Show all outputs (packages, apps, etc.) |
| `nix flake show github:user/repo` | Show remote flake outputs |
| `nix flake metadata` | Show flake metadata (git revision, etc.) |
| `nix flake metadata --refresh` | **Force refresh cached flake metadata** |
| `nix flake metadata --json` | Get metadata as JSON |
| `nix flake info` | Alias for metadata |

### Updating Flakes

| Command | Purpose |
|---------|---------|
| `nix flake update` | Update all inputs (flake.lock) |
| `nix flake update nixpkgs` | Update specific input |
| `nix flake update --commit-lock-file` | Update and commit flake.lock |
| `nix flake lock` | Regenerate flake.lock without updating |
| `nix flake lock --update-input nixpkgs` | Update specific input only |

### Checking Flakes

| Command | Purpose |
|---------|---------|
| `nix flake check` | Run all checks (formatting, tests, etc.) |
| `nix flake check --show-trace` | Check with full error traces |
| `nix flake check --all-systems` | Check for all systems |

---

## Cache Management

### The Problem We Had: Stale GitHub Flake Cache

When you push to GitHub but `nix run github:...` uses old code:

#### Solution 1: Refresh Flake Metadata (Recommended)

```bash
# Refresh the specific flake
nix flake metadata github:0xdsqr/nixos-config --refresh

# Now it will use the latest commit
nix run github:0xdsqr/nixos-config#sysdsqr
```

#### Solution 2: Clear Fetcher Cache

```bash
# Nuclear option: clear all fetcher cache
rm -rf ~/.cache/nix/fetcher-cache-v1.sqlite*

# Or just the eval cache
rm -rf ~/.cache/nix/eval-cache-v*
```

#### Solution 3: Use Specific Commit

```bash
# Bypass cache by specifying exact commit
nix run github:0xdsqr/nixos-config/9c6d0d6#sysdsqr
```

### General Cache Commands

| Command | Purpose |
|---------|---------|
| `nix flake metadata --refresh` | Refresh flake cache (most common) |
| `nix store optimise` | Deduplicate store (save disk space) |
| `nix store verify --all` | Verify store integrity |
| `nix store repair` | Repair corrupted store paths |
| `nix-collect-garbage -d` | Clean old generations + garbage collect |

### Cache Locations

| Path | Contents |
|------|----------|
| `~/.cache/nix/fetcher-cache-v1.sqlite*` | GitHub/URL fetch cache |
| `~/.cache/nix/eval-cache-v*` | Evaluation cache |
| `/nix/store` | Nix store (built packages) |
| `~/.nix-profile` | User profile |

---

## Garbage Collection

### Basic Garbage Collection

| Command | Purpose |
|---------|---------|
| `nix-collect-garbage` | Delete unreferenced store paths |
| `nix-collect-garbage -d` | **Delete old generations + garbage collect** |
| `nix-collect-garbage --delete-older-than 7d` | Delete generations older than 7 days |
| `nix store gc` | Flake-style garbage collection |

### Checking Disk Usage

| Command | Purpose |
|---------|---------|
| `du -sh /nix/store` | Check store size |
| `nix path-info --all --human-readable --closure-size` | List all paths with sizes |
| `nix store df` | Show store disk usage |

### Profile Management

| Command | Purpose |
|---------|---------|
| `nix profile list` | List installed packages |
| `nix profile history` | Show profile generations |
| `nix profile rollback` | Roll back to previous generation |
| `nix profile wipe-history` | Delete old generations |

### Example Cleanup Workflow

```bash
# 1. See what's installed
nix profile list

# 2. Remove old generations (older than 30 days)
nix-collect-garbage --delete-older-than 30d

# 3. Optimize store (deduplicate)
nix store optimise

# 4. Check disk usage
du -sh /nix/store
```

---

## Building & Running

### Building Packages

| Command | Purpose |
|---------|---------|
| `nix build` | Build default package (creates ./result) |
| `nix build .#sysdsqr` | Build specific package |
| `nix build github:user/repo#pkg` | Build from GitHub |
| `nix build .#sysdsqr --rebuild` | Force rebuild (ignore cache) |
| `nix build --print-build-logs` | Show build output (verbose) |
| `nix build -L` | Show build logs (short form) |

### Running Applications

| Command | Purpose |
|---------|---------|
| `nix run` | Run default app |
| `nix run .#sysdsqr` | Run specific app |
| `nix run github:user/repo#app` | Run from GitHub |
| `nix run .#sysdsqr -- arg1 arg2` | Run with arguments |

### Development Shells

| Command | Purpose |
|---------|---------|
| `nix develop` | Enter dev shell (from flake.nix) |
| `nix develop -c bash` | Enter dev shell with bash |
| `nix develop .#devShell` | Enter specific dev shell |
| `nix develop --command 'npm install'` | Run command in dev shell |

### Installing Packages

| Command | Purpose |
|---------|---------|
| `nix profile install .#sysdsqr` | Install package to profile |
| `nix profile install github:user/repo#pkg` | Install from GitHub |
| `nix profile upgrade '.*'` | Upgrade all packages |
| `nix profile upgrade '.*sysdsqr.*'` | Upgrade specific package |
| `nix profile remove '.*sysdsqr.*'` | Remove package |

---

## Debugging

### Build Debugging

| Command | Purpose |
|---------|---------|
| `nix build --print-build-logs` | Show full build logs |
| `nix build --show-trace` | Show full error traces |
| `nix build --keep-failed` | Keep failed build directory |
| `nix build --verbose` | Verbose output |
| `nix log /nix/store/...drv` | Show logs for completed build |

### Evaluation Debugging

| Command | Purpose |
|---------|---------|
| `nix eval .#packages.x86_64-linux.sysdsqr` | Evaluate expression |
| `nix eval --json .#packages.x86_64-linux` | Eval as JSON |
| `nix eval --show-trace` | Show full evaluation trace |
| `nix repl` | Start REPL to explore |

### In the Nix REPL

```bash
nix repl
# Inside REPL:
:lf .                          # Load flake
packages.x86_64-linux         # Explore packages
:q                             # Quit
```

### Dependency Analysis

| Command | Purpose |
|---------|---------|
| `nix why-depends ./result /nix/store/...` | Why does result depend on path? |
| `nix path-info --closure-size ./result` | Show closure size |
| `nix-store --query --requisites ./result` | List all dependencies |
| `nix-store --query --referrers /nix/store/...` | What depends on this? |

---

## System Management

### NixOS

| Command | Purpose |
|---------|---------|
| `sudo nixos-rebuild switch --flake .` | Rebuild and switch |
| `sudo nixos-rebuild boot --flake .` | Rebuild (activate on reboot) |
| `sudo nixos-rebuild test --flake .` | Test without adding generation |
| `sudo nixos-rebuild dry-activate --flake .` | Show what would change |
| `nixos-rebuild list-generations` | List system generations |
| `sudo nixos-rebuild switch --rollback` | Rollback to previous |

### Home Manager

| Command | Purpose |
|---------|---------|
| `home-manager switch --flake .` | Rebuild home configuration |
| `home-manager generations` | List generations |
| `home-manager packages` | List installed packages |

### nix-darwin (macOS)

| Command | Purpose |
|---------|---------|
| `darwin-rebuild switch --flake .` | Rebuild darwin configuration |
| `darwin-rebuild check --flake .` | Check configuration |

---

## Common Workflows

### Workflow 1: Update All Inputs and Rebuild

```bash
# 1. Update flake.lock
nix flake update

# 2. Rebuild system
sudo nixos-rebuild switch --flake .

# 3. Clean up old stuff
nix-collect-garbage -d
```

### Workflow 2: Fix Stale GitHub Cache

```bash
# Someone pushed new code but you're getting old version
nix flake metadata github:0xdsqr/nixos-config --refresh
nix run github:0xdsqr/nixos-config#sysdsqr
```

### Workflow 3: Deep Clean (Free Disk Space)

```bash
# 1. Remove old generations (>30 days)
nix-collect-garbage --delete-older-than 30d

# 2. Garbage collect unreferenced paths
nix store gc

# 3. Optimize store (deduplicate)
nix store optimise

# 4. Check results
du -sh /nix/store
```

### Workflow 4: Debug a Build Failure

```bash
# 1. Try building with logs
nix build .#sysdsqr --print-build-logs

# 2. If that doesn't help, add trace
nix build .#sysdsqr --show-trace

# 3. Keep failed build to inspect
nix build .#sysdsqr --keep-failed
# Then cd to the failed build path shown

# 4. Check the derivation
nix show-derivation .#sysdsqr
```

### Workflow 5: Test Changes Without Committing

```bash
# 1. Make changes to flake
vim flake.nix

# 2. Build locally (doesn't require git commit)
nix build .#sysdsqr

# 3. Test the result
./result/bin/sysdsqr

# 4. If good, commit
git add flake.nix
git commit -m "update: flake changes"
git push
```

---

## Quick Reference Card

### Most Used Commands

| Task | Command |
|------|---------|
| **Refresh GitHub flake** | `nix flake metadata github:user/repo --refresh` |
| **Update all inputs** | `nix flake update` |
| **Clean old generations** | `nix-collect-garbage -d` |
| **Build package** | `nix build .#package` |
| **Run app** | `nix run .#app` |
| **Show flake outputs** | `nix flake show` |
| **Enter dev shell** | `nix develop` |
| **Optimize store** | `nix store optimise` |
| **Check flake** | `nix flake check` |
| **Rebuild NixOS** | `sudo nixos-rebuild switch --flake .` |

### Emergency Commands

| Problem | Solution |
|---------|----------|
| Stale GitHub cache | `nix flake metadata --refresh` |
| Disk full | `nix-collect-garbage -d && nix store optimise` |
| Build failed | `nix build --print-build-logs --show-trace` |
| System broken | `sudo nixos-rebuild switch --rollback` |
| Corrupted store | `nix store verify --all && nix store repair` |

---

## Additional Resources

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
- **Home Manager**: https://nix-community.github.io/home-manager/

---

## Tips & Tricks

### 1. Add Alias for Common Commands

Add to your shell RC file:

```bash
# ~/.bashrc or ~/.zshrc
alias nfu="nix flake update"
alias nfm="nix flake metadata --refresh"
alias nfs="nix flake show"
alias nbc="nix build --print-build-logs"
alias ngc="nix-collect-garbage -d"
```

### 2. Use direnv for Auto Dev Shell

Create `.envrc` in project root:

```bash
use flake
```

Then `direnv allow` - automatically enters dev shell when you cd into the directory.

### 3. Keep Build Logs for Failed Builds

Add to `~/.config/nix/nix.conf`:

```
keep-outputs = true
keep-derivations = true
```

### 4. Enable More Verbose Errors

```bash
export NIX_DEBUG_INFO=1
nix build .#package --show-trace
```

### 5. Check What Changed Before Rebuild

```bash
# NixOS
sudo nixos-rebuild dry-activate --flake .

# Home Manager
home-manager switch --flake . -n
```

---

## Understanding Nix Store Paths

Every build creates a unique path based on inputs:

```
/nix/store/hash-name-version
           ^^^^
           Changes if ANY input changes
```

**Example:**
```
/nix/store/abc123...-sysdsqr-0.1.0
```

If you change:
- Source code
- Dependencies
- Build flags
- Anything in the derivation

→ New hash, new store path

This is why Nix is reproducible!
