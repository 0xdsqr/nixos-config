# sysdsqr CLI - Usage in Other Projects

## Testing Locally

### Build and Run

```bash
# In nixos-config repo
nix build .#sysdsqr

# Run the binary
./result/bin/sysdsqr
```

### Using nix run

```bash
# From nixos-config repo
nix run .#sysdsqr

# From anywhere (if pushed to GitHub)
nix run github:yourusername/nixos-config#sysdsqr
```

---

## Using in Other Projects

### Option 1: Add as Flake Input

```nix
# In your project's flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dsqr-nix.url = "github:yourusername/nixos-config";
  };

  outputs = { self, nixpkgs, dsqr-nix, ... }: {
    # Add to devShell
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        dsqr-nix.packages.x86_64-linux.sysdsqr
      ];
    };

    # Or add to system packages
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          dsqr-nix.packages.x86_64-linux.sysdsqr
        ];
      }];
    };
  };
}
```

Then:
```bash
# Enter dev shell
nix develop

# Or install system-wide
nixos-rebuild switch --flake .
```

### Option 2: Direct nix run

```bash
# Run without installing
nix run github:yourusername/nixos-config#sysdsqr
```

### Option 3: Install to Profile

```bash
# Install to user profile
nix profile install github:yourusername/nixos-config#sysdsqr

# Run anywhere
sysdsqr
```

---

## Local Development Testing

### Test Changes Without Committing

```bash
# In nixos-config repo
nix build .#sysdsqr

# Test the binary
./result/bin/sysdsqr

# Or run directly
nix run .#sysdsqr
```

### Test in Another Project Locally

```bash
# In your other project's flake.nix
{
  inputs = {
    dsqr-nix.url = "path:/Users/dsqr/workspace/code/nixos-config";
  };
}
```

Then rebuild/develop as normal.

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Test with sysdsqr

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          github_access_token: ${{ secrets.GITHUB_TOKEN }}

      - name: Run sysdsqr
        run: |
          nix run github:yourusername/nixos-config#sysdsqr
```

---

## Troubleshooting

### Binary Not Found

```bash
# Check if package exists
nix flake show github:yourusername/nixos-config

# Should show:
# packages
#   └─x86_64-linux
#     ├─default: package 'sysdsqr'
#     └─sysdsqr: package 'sysdsqr'
```

### Build Errors

```bash
# Clean build
nix build .#sysdsqr --rebuild

# Show full build output
nix build .#sysdsqr -L
```

### Testing Different Architectures

```bash
# Build for x86_64-linux
nix build .#packages.x86_64-linux.sysdsqr

# Build for aarch64-linux (if supported)
nix build .#packages.aarch64-linux.sysdsqr
```

---

## Quick Reference

```bash
# Local build
nix build .#sysdsqr

# Local run
nix run .#sysdsqr

# Remote run
nix run github:yourusername/nixos-config#sysdsqr

# Install to profile
nix profile install github:yourusername/nixos-config#sysdsqr

# Remove from profile
nix profile remove sysdsqr
```
