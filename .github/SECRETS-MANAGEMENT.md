# Secrets Management with SOPS

**Comprehensive guide for managing secrets across your NixOS homelab using SOPS + age encryption.**

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Initial Setup (One-Time)](#initial-setup-one-time)
3. [Adding a New Machine](#adding-a-new-machine)
4. [Editing Secrets](#editing-secrets)
5. [Maintenance Operations](#maintenance-operations)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Key Concepts

- **age encryption**: Modern, simple encryption tool (better than GPG for this use case)
- **SOPS**: Encrypts values but keeps keys readable in YAML files
- **sops-nix**: NixOS module that auto-decrypts secrets at activation time

### Key Storage Locations

**Standard locations (DO NOT change these):**

| Location | What | Owner | Permissions |
|----------|------|-------|-------------|
| `~/.config/sops/age/keys.txt` | Admin private key (Mac) | Your user | 600 |
| `/var/lib/sops-nix/key.txt` | Host private key (VM) | root | 600 |
| `.sops.yaml` | Encryption policy (repo) | git | 644 |
| `secrets/hosts/<hostname>.sops.yaml` | Encrypted secrets (repo) | git | 644 |
| `keys/hosts/<hostname>.pub` | Host public keys (repo, reference only) | git | 644 |

### Security Model

```
┌─────────────────────────────────────────────────────────┐
│ Your Mac                                                 │
│ ~/.config/sops/age/keys.txt (admin private key)         │
│ Can decrypt: ALL secrets (for editing/management)       │
└─────────────────────────────────────────────────────────┘
                           │
                           │ sops edit
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Git Repo                                                 │
│ secrets/hosts/hoo-vm-x86_64.sops.yaml (encrypted)       │
│ Keys readable, values encrypted                          │
└─────────────────────────────────────────────────────────┘
                           │
                           │ nixos-rebuild
                           ▼
┌─────────────────────────────────────────────────────────┐
│ VM: hoo-vm-x86_64                                        │
│ /var/lib/sops-nix/key.txt (host private key)            │
│ Can decrypt: ONLY hoo-vm-x86_64.sops.yaml               │
│ Secrets live in: /run/secrets/* (tmpfs, memory only)    │
└─────────────────────────────────────────────────────────┘
```

**Why per-host keys?** If one VM is compromised, attacker can't decrypt other VMs' secrets.

---

## Initial Setup (One-Time)

### Step 1: Install SOPS Tools (Mac)

```bash
cd ~/workspace/code/nixos-config
nix develop  # Enters dev shell with sops/age/ssh-to-age
```

### Step 2: Generate Admin Age Key (Mac)

```bash
# Create directory
mkdir -p ~/.config/sops/age

# Generate key
age-keygen -o ~/.config/sops/age/keys.txt

# Set permissions
chmod 600 ~/.config/sops/age/keys.txt

# View public key (SAVE THIS)
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1abc123...xyz
```

**⚠️ IMPORTANT:** Back up `~/.config/sops/age/keys.txt` to your password manager. If you lose this, you lose access to all secrets.

### Step 3: Create Repo Structure

```bash
mkdir -p secrets/hosts secrets/shared keys/hosts
```

### Step 4: Create .sops.yaml

```bash
cat > .sops.yaml << 'EOF'
keys:
  # Admin key (your Mac) - REPLACE WITH YOUR KEY FROM STEP 2
  - &admin age1abc123...xyz

  # Host keys (add as you provision VMs)
  # - &hoo age1...
  # - &gateway age1...

creation_rules:
  # Template (uncomment and duplicate for each host)
  # - path_regex: secrets/hosts/HOSTNAME\.sops\.ya?ml$
  #   key_groups:
  #     - age:
  #         - *admin
  #         - *HOSTNAME_KEY
EOF
```

**Edit `.sops.yaml`** and replace `age1abc123...xyz` with your actual admin public key.

---

## Adding a New Machine

### When to Add a New Machine

Add secrets for a machine when it needs to:
- Access external APIs (GitHub tokens, Cloudflare API, etc.)
- Store passwords for services (Redis, PostgreSQL, Grafana, etc.)
- Authenticate to other services (SSH keys, certificates, etc.)

**Don't create secrets if:** The machine only runs public services with no credentials.

---

### Step-by-Step: Add New Machine

**Example:** Adding `gateway-vm-x86_64`

#### 1. Generate Host Key (On VM)

```bash
# SSH to the VM
ssh sysdsqr@gateway.dsqr.dev

# Install age (if not already present)
sudo nix-env -iA nixos.age

# Create standard directory
sudo mkdir -p /var/lib/sops-nix

# Generate host key
sudo age-keygen -o /var/lib/sops-nix/key.txt

# Set permissions
sudo chmod 600 /var/lib/sops-nix/key.txt

# View and COPY public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1xyz789...abc (COPY THIS)

# Exit VM
exit
```

#### 2. Update .sops.yaml (On Mac)

```bash
# Edit .sops.yaml
```

Add the host key and creation rule:

```yaml
keys:
  - &admin age1abc123...xyz
  - &gateway age1xyz789...abc  # ADD THIS

creation_rules:
  # Gateway VM - ADD THIS SECTION
  - path_regex: secrets/hosts/gateway-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *gateway
```

#### 3. Save Host Public Key (On Mac)

```bash
# Save for reference (not required, but helpful)
echo "age1xyz789...abc" > keys/hosts/gateway-vm-x86_64.pub
```

#### 4. Create Secrets File (On Mac)

```bash
# Create encrypted file (will open editor)
sops secrets/hosts/gateway-vm-x86_64.sops.yaml
```

**In the editor, add secrets in plain YAML:**

```yaml
# Example for gateway with VPN service
wireguard:
  private_key: "your-wireguard-private-key"

cloudflare:
  api_token: "your-cloudflare-token"
```

**Save and exit.** SOPS encrypts automatically.

#### 5. Verify Encryption (On Mac)

```bash
# Should see ENC[...] for values
cat secrets/hosts/gateway-vm-x86_64.sops.yaml

# Should show plain text
sops -d secrets/hosts/gateway-vm-x86_64.sops.yaml
```

#### 6. Configure Machine (On Mac)

Edit `machines/gateway-vm-x86_64.nix`:

```nix
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware/vm-x86_64-linux.nix
    (inputs.self.nixosModules.dsqr-proxmox inputs)
    inputs.sops-nix.nixosModules.sops
  ];

  # SOPS configuration
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.defaultSopsFile = ../secrets/hosts/gateway-vm-x86_64.sops.yaml;

  # Define secrets with correct ownership
  sops.secrets."wireguard/private_key" = {
    owner = "root";
    mode = "0400";
  };

  sops.secrets."cloudflare/api_token" = {
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  # Use secrets in services
  networking.wireguard.interfaces.wg0 = {
    privateKeyFile = config.sops.secrets."wireguard/private_key".path;
  };

  services.caddy.environmentFile = config.sops.secrets."cloudflare/api_token".path;

  # ... rest of config ...
}
```

#### 7. Commit and Deploy (On Mac)

```bash
# Commit encrypted secrets
git add .sops.yaml secrets/ keys/ machines/gateway-vm-x86_64.nix
git commit -m "feat: add SOPS secrets for gateway-vm-x86_64"

# Deploy
NIXNAME=gateway-vm-x86_64 just switch
```

#### 8. Verify on VM

```bash
ssh sysdsqr@gateway.dsqr.dev

# Check secrets directory
sudo ls -la /run/secrets/

# Should see:
# drwxr-xr-x 3 root root  60 Dec 18 15:00 .
# drwxr-xr-x 30 root root 860 Dec 18 15:00 ..
# drwx------  2 root root  80 Dec 18 15:00 wireguard/
# -r--------  1 caddy caddy 40 Dec 18 15:00 cloudflare/api_token

# Verify service can read secret
sudo systemctl status wireguard-wg0.service
```

---

## Editing Secrets

### Edit Existing Secrets

```bash
# On Mac
sops secrets/hosts/gateway-vm-x86_64.sops.yaml
```

Edit values in plain text, save, exit. SOPS re-encrypts automatically.

### View Secrets Without Editing

```bash
sops -d secrets/hosts/gateway-vm-x86_64.sops.yaml
```

### Add New Secret to Existing File

```bash
sops secrets/hosts/gateway-vm-x86_64.sops.yaml
# Add new key/value pairs
```

Then update the machine config to use the new secret:

```nix
sops.secrets."new/secret" = {
  owner = "service-user";
  mode = "0400";
};
```

---

## Maintenance Operations

### Rotate Host Key (After Compromise or Migration)

**On VM:**
```bash
# Generate new key
sudo age-keygen -o /var/lib/sops-nix/key.txt.new
sudo mv /var/lib/sops-nix/key.txt.new /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# Get new public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

**On Mac:**
```bash
# Update .sops.yaml with new public key
# Then re-encrypt all secrets for that host
sops updatekeys secrets/hosts/gateway-vm-x86_64.sops.yaml

# Commit and deploy
git add .sops.yaml secrets/hosts/gateway-vm-x86_64.sops.yaml
git commit -m "security: rotate host key for gateway-vm-x86_64"
NIXNAME=gateway-vm-x86_64 just switch
```

### Rotate Admin Key (If Lost or Compromised)

**⚠️ DANGER ZONE** - You'll need to re-encrypt ALL secrets.

```bash
# Generate new admin key
age-keygen -o ~/.config/sops/age/keys.txt.new
mv ~/.config/sops/age/keys.txt.new ~/.config/sops/age/keys.txt

# Update .sops.yaml with new admin public key
# Re-encrypt ALL secret files
for file in secrets/hosts/*.sops.yaml; do
  sops updatekeys "$file"
done

# Commit
git add .sops.yaml secrets/
git commit -m "security: rotate admin key"
```

### Remove a Machine

```bash
# 1. Remove from .sops.yaml (keys and creation_rules)
# 2. Delete secrets file
rm secrets/hosts/old-machine.sops.yaml
rm keys/hosts/old-machine.pub

# 3. Remove machine config
rm machines/old-machine.nix

# 4. Update flake.nix (remove nixosConfigurations entry)

# 5. Commit
git add -A
git commit -m "chore: remove old-machine"
```

### Check Which Keys Can Decrypt a File

```bash
sops filestatus secrets/hosts/gateway-vm-x86_64.sops.yaml
```

---

## Troubleshooting

### "no keys could decrypt the data"

**Cause:** Your admin key isn't in `~/.config/sops/age/keys.txt` or doesn't match `.sops.yaml`.

**Fix:**
```bash
# Verify key exists
cat ~/.config/sops/age/keys.txt

# Check public key matches .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
grep admin .sops.yaml
```

### "error loading config: no matching creation rules found"

**Cause:** File path doesn't match any `path_regex` in `.sops.yaml`.

**Fix:**
```bash
# Check file path
echo "secrets/hosts/gateway-vm-x86_64.sops.yaml"

# Check .sops.yaml regex
cat .sops.yaml | grep path_regex

# Make sure they match!
```

### Service Can't Read Secret

**Cause:** Wrong owner/group/permissions on secret.

**Fix:**
```nix
sops.secrets."service/password" = {
  owner = "correct-service-user";  # Check systemd service user
  group = "correct-group";
  mode = "0400";  # Read-only for owner
};
```

Check service user:
```bash
sudo systemctl cat service-name.service | grep User=
```

### "cannot stat '/var/lib/sops-nix/key.txt'"

**Cause:** Host key doesn't exist on VM.

**Fix:** Follow "Adding a New Machine" steps to generate host key.

### Secrets Work on Mac But Not on VM

**Cause:** Host key on VM doesn't match public key in `.sops.yaml`.

**Fix:**
```bash
# On VM: Get actual public key
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Compare with .sops.yaml
grep hostname .sops.yaml

# If different, update .sops.yaml and re-encrypt
sops updatekeys secrets/hosts/hostname.sops.yaml
```

---

## Quick Reference

### Common Commands

```bash
# Create new secret file
sops secrets/hosts/hostname.sops.yaml

# Edit existing secrets
sops secrets/hosts/hostname.sops.yaml

# View decrypted secrets
sops -d secrets/hosts/hostname.sops.yaml

# Check who can decrypt
sops filestatus secrets/hosts/hostname.sops.yaml

# Re-encrypt after key change
sops updatekeys secrets/hosts/hostname.sops.yaml

# Verify secrets on VM
ssh user@host sudo ls -la /run/secrets/
```

### Standard File Structure

```
nixos-config/
├── .sops.yaml                          # Encryption policy
├── secrets/
│   └── hosts/                          # Per-host secrets
│       ├── hoo-vm-x86_64.sops.yaml
│       ├── gateway-vm-x86_64.sops.yaml
│       └── github-runner-vm-x86_64.sops.yaml
├── keys/
│   └── hosts/                          # Public keys (reference)
│       ├── hoo-vm-x86_64.pub
│       ├── gateway-vm-x86_64.pub
│       └── github-runner-vm-x86_64.pub
└── machines/
    ├── hoo-vm-x86_64.nix              # Machine configs with sops
    ├── gateway-vm-x86_64.nix
    └── github-runner-vm-x86_64.nix
```

### Checklist: Adding New Machine

- [ ] SSH to VM, generate host key at `/var/lib/sops-nix/key.txt`
- [ ] Copy host public key
- [ ] Add host key to `.sops.yaml` (keys section)
- [ ] Add creation rule to `.sops.yaml` (creation_rules section)
- [ ] Save host public key to `keys/hosts/<hostname>.pub`
- [ ] Create `secrets/hosts/<hostname>.sops.yaml`
- [ ] Add secrets in plain YAML, save (auto-encrypts)
- [ ] Update `machines/<hostname>.nix` with sops config
- [ ] Define each secret with owner/group/mode
- [ ] Commit: `.sops.yaml`, `secrets/`, `keys/`, `machines/`
- [ ] Deploy: `NIXNAME=<hostname> just switch`
- [ ] Verify: SSH to VM, check `/run/secrets/`

---

## Why This Setup?

**age over GPG:** Simpler, faster, no keyservers, designed for file encryption.

**Per-host keys:** Compromised VM can't decrypt other VMs' secrets.

**Single admin key:** Homelab scale doesn't need multiple admins. You're the authority.

**sops-nix:** Secrets decrypted at activation, stored in tmpfs (memory-only), never in Nix store.

**Git-safe:** Encrypted values safe to commit. Track changes over time.

**Standard locations:** `/var/lib/sops-nix/key.txt` on all VMs - predictable, no surprises.
