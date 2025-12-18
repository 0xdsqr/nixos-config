# SOPS Onboarding Guide

**SOPS (Secrets OPerationS)** is a tool for encrypting configuration files with keys remaining readable but values encrypted. This guide sets up SOPS + sops-nix for your NixOS homelab.

## Overview

**What we're setting up:**
- **age** encryption (simpler than GPG, offline-friendly)
- **sops-nix** for automatic secret decryption at system activation
- **Per-host secrets** (each VM decrypts only its own secrets)
- **Single admin key** (your Mac can decrypt everything for management)

**Key architecture:**
- Admin key (on Mac): Can decrypt all secrets for editing/rotation
- Host keys (on each VM): Can only decrypt that specific host's secrets
- SSH-to-age: Derive age keys from existing SSH keys (less key sprawl)

## Directory Structure

```
nixos-config/
├── secrets/
│   ├── hosts/                          # Per-host encrypted secrets
│   │   ├── hoo-vm-x86_64.sops.yaml
│   │   ├── gateway-vm-x86_64.sops.yaml
│   │   └── dsqr-server-vm-x86_64.sops.yaml
│   └── shared/                         # Shared secrets (rare)
│       └── cloudflare.sops.yaml
├── keys/
│   └── hosts/                          # Host public age keys (for reference)
│       ├── hoo.pub
│       ├── gateway.pub
│       └── dsqr-server.pub
└── .sops.yaml                          # Encryption policy (which keys can decrypt which files)
```

## Setup Process

### 1. Prerequisites Installed

You need:
- `age` - encryption tool
- `sops` - secret editor
- `ssh-to-age` - convert SSH keys to age format

These will be added to your flake devShell.

### 2. Generate Admin Age Key (One-time)

On your Mac, generate a single admin key:

```bash
# Generate admin age key
age-keygen -o ~/.config/sops/age/keys.txt

# Set permissions
chmod 600 ~/.config/sops/age/keys.txt

# View public key (save this!)
age-keygen -y ~/.config/sops/age/keys.txt
```

**Save the public key** - you'll add it to `.sops.yaml`.

### 3. Generate Host Age Keys

For each VM, you'll generate an age key that lives **only on that host**.

**On each VM after first boot:**

```bash
# Create directory
sudo mkdir -p /var/lib/sops-nix

# Generate host age key
sudo age-keygen -o /var/lib/sops-nix/key.txt

# Set permissions (only root can read)
sudo chmod 600 /var/lib/sops-nix/key.txt

# View public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

Copy the public key and add it to your repo's `.sops.yaml`.

**Alternative: Derive from SSH host key** (automated, no manual key generation):
- sops-nix can automatically convert SSH host keys to age format
- More complex setup but zero manual key generation
- Not recommended for first-time SOPS users

### 4. Create `.sops.yaml` Policy

This file defines **who can decrypt what**:

```yaml
keys:
  # Admin key (your Mac)
  - &admin age1youradminpublickey...

  # Host keys
  - &hoo age1hoopublickey...
  - &gateway age1gatewaypublickey...
  - &dsqr_server age1dsqrserverpublickey...

creation_rules:
  # Per-host secrets (most common pattern)
  - path_regex: secrets/hosts/hoo-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *hoo

  - path_regex: secrets/hosts/gateway-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *gateway

  - path_regex: secrets/hosts/dsqr-server-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *dsqr_server

  # Shared secrets (all hosts can decrypt)
  - path_regex: secrets/shared/.*\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *hoo
          - *gateway
          - *dsqr_server
```

### 5. Create First Secret File

Create an encrypted secret file for a host:

```bash
# Create directory
mkdir -p secrets/hosts

# Create and edit encrypted file (SOPS will use .sops.yaml rules)
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**Inside the editor, add your secrets in YAML format:**

```yaml
redis:
  password: your-secure-redis-password

grafana:
  admin_password: your-secure-grafana-password

prometheus:
  redis_exporter_password: your-secure-redis-password
```

Save and exit. SOPS encrypts the values but keeps keys readable:

```yaml
redis:
    password: ENC[AES256_GCM,data:encrypted-data-here,iv:...,tag:...,type:str]
grafana:
    admin_password: ENC[AES256_GCM,data:more-encrypted-data,iv:...,tag:...,type:str]
```

### 6. Configure sops-nix in Flake

Add sops-nix input to `flake.nix`:

```nix
inputs = {
  # ... existing inputs ...
  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
};
```

Import the module in your NixOS configuration.

### 7. Wire Secrets in NixOS Config

Create a secrets module that points sops-nix at the right file:

```nix
# In your machine config (e.g., machines/hoo-vm-x86_64.nix)
{
  # Tell sops-nix where the host's private key is
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Tell sops-nix which encrypted file to use
  sops.defaultSopsFile = ../secrets/hosts/hoo-vm-x86_64.sops.yaml;

  # Define each secret you want to decrypt
  sops.secrets."redis/password" = {
    owner = "redis";
    group = "redis";
    mode = "0400";
  };

  sops.secrets."grafana/admin_password" = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Use the secrets in your services
  services.redis.servers.main.settings.requirepass =
    config.sops.secrets."redis/password".path;

  services.grafana.settings.security.admin_password =
    config.sops.secrets."grafana/admin_password".path;
}
```

At activation time, sops-nix:
1. Decrypts secrets using `/var/lib/sops-nix/key.txt`
2. Writes them to `/run/secrets/redis/password` (tmpfs, memory-only)
3. Sets correct owner/group/permissions
4. Services read from those paths

### 8. Rebuild and Activate

```bash
# From your Mac (if using remote build)
NIXNAME=hoo-vm-x86_64 just switch

# Or on the VM directly
sudo nixos-rebuild switch --flake .#hoo-vm-x86_64
```

## Common Operations

### Edit a secret

```bash
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

SOPS uses `.sops.yaml` to know which keys can decrypt this file.

### Add a new secret to existing file

```bash
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
# Add new key/value pairs in your editor
```

### Rotate keys (when a host key changes)

```bash
# Update .sops.yaml with new public key
# Re-encrypt all files for that host
sops updatekeys secrets/hosts/hoo-vm-x86_64.sops.yaml
```

### View encrypted file without editing

```bash
sops -d secrets/hosts/hoo-vm-x86_64.sops.yaml
```

### Verify who can decrypt a file

```bash
sops filestatus secrets/hosts/hoo-vm-x86_64.sops.yaml
```

## Adding a New VM

When provisioning a new VM that needs secrets:

1. **Boot the VM** (initial boot without secrets is fine)
2. **Generate host key** on the VM:
   ```bash
   sudo mkdir -p /var/lib/sops-nix
   sudo age-keygen -o /var/lib/sops-nix/key.txt
   sudo chmod 600 /var/lib/sops-nix/key.txt
   sudo age-keygen -y /var/lib/sops-nix/key.txt  # Copy public key
   ```
3. **Add public key to `.sops.yaml`** in your repo
4. **Create secret file** for the new host:
   ```bash
   sops secrets/hosts/new-vm.sops.yaml
   ```
5. **Update machine config** to wire sops-nix
6. **Rebuild** the VM:
   ```bash
   sudo nixos-rebuild switch --flake .#new-vm
   ```

## Security Best Practices

1. **Never commit private keys** - only public keys go in git
2. **Admin key backup** - Store your `~/.config/sops/age/keys.txt` safely (password manager, encrypted backup)
3. **Per-host isolation** - Each host can only decrypt its own secrets
4. **Rotate on compromise** - If a host key is compromised, generate new key and run `sops updatekeys`
5. **Use tmpfs** - sops-nix writes decrypted secrets to `/run/secrets/` (tmpfs, memory-only, cleared on reboot)
6. **Least privilege** - Set correct owner/group/mode on each secret

## Troubleshooting

### "no keys could decrypt the data"

- Verify your admin key is in `~/.config/sops/age/keys.txt`
- Check `.sops.yaml` path_regex matches your file path
- Run `sops filestatus <file>` to see which keys are configured

### "cannot stat '/var/lib/sops-nix/key.txt'"

- The host key doesn't exist yet - generate it first
- Or the path in your config doesn't match where you put the key

### Service can't read secret file

- Check `sops.secrets.<name>.owner/group/mode` settings
- Verify the service user/group matches
- Check systemd service logs: `journalctl -u <service-name>`

### Want to test decryption manually

```bash
# View decrypted content
sops -d secrets/hosts/hoo-vm-x86_64.sops.yaml

# Check which keys can access the file
sops filestatus secrets/hosts/hoo-vm-x86_64.sops.yaml
```

## Why This Setup?

**Age over GPG:** Simpler, faster, designed for file encryption, no keyservers needed.

**Per-host keys:** If one VM is compromised, attacker can't decrypt other hosts' secrets.

**Single admin key:** Homelab scale doesn't need multiple admins. You're the single source of truth.

**sops-nix integration:** Secrets are decrypted at activation time, not stored decrypted in Nix store. Services get correct permissions automatically.

**Git-friendly:** Encrypted files can be committed. Diffs show which keys changed (not values). Easy to track secret changes over time.

## Further Reading

- [SOPS GitHub](https://github.com/getsops/sops)
- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [Age specification](https://age-encryption.org/)
