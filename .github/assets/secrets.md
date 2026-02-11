# Secrets Management

This configuration uses **SOPS (Secrets OPerationS)** with **age** encryption for managing secrets across all machines.

## Architecture

- **Single admin key** on your Mac - can decrypt/edit all secrets
- **Per-host keys** on each VM - can only decrypt that host's secrets
- **Git-friendly** - encrypted values stored in repo, safe to commit
- **Automatic decryption** - sops-nix decrypts at activation time into tmpfs

## Setup

### 1. Generate Admin Key (one-time, on your Mac)

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt  # Save this public key
```

### 2. Generate Host Key (on each VM)

```bash
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo age-keygen -y /var/lib/sops-nix/key.txt  # Save this public key
```

### 3. Create `.sops.yaml`

```yaml
keys:
  - &admin age1youradminkey...
  - &myhost age1hostkey...

creation_rules:
  - path_regex: secrets/hosts/myhost-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *myhost
```

### 4. Create Encrypted Secret File

```bash
sops secrets/hosts/myhost-vm-x86_64.sops.yaml
```

### 5. Configure in Machine

```nix
{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.defaultSopsFile = ../secrets/hosts/myhost-vm-x86_64.sops.yaml;

  sops.secrets."redis/password" = {
    owner = "redis";
    mode = "0400";
  };

  services.redis.servers.main.settings.requirepass =
    builtins.readFile config.sops.secrets."redis/password".path;
}
```

### 6. Deploy

```bash
NIXNAME=myhost-vm-x86_64 just switch
```

## Common Operations

**Edit secrets:**
```bash
sops secrets/hosts/myhost-vm-x86_64.sops.yaml
```

**View decrypted (without editing):**
```bash
sops -d secrets/hosts/myhost-vm-x86_64.sops.yaml
```

**Rotate keys:**
```bash
# After updating .sops.yaml with new key
sops updatekeys secrets/hosts/myhost-vm-x86_64.sops.yaml
```

**Verify secret files on VM:**
```bash
sudo ls -la /run/secrets/
```

## Adding Secrets to a New VM

1. Boot the VM
2. SSH to VM and generate host key:
   ```bash
   sudo mkdir -p /var/lib/sops-nix
   sudo age-keygen -o /var/lib/sops-nix/key.txt
   sudo age-keygen -y /var/lib/sops-nix/key.txt  # Copy this public key
   ```
3. Add host public key to `.sops.yaml`
4. Create `secrets/hosts/<hostname>.sops.yaml` using `sops`
5. Configure sops-nix in machine config
6. Rebuild and deploy: `NIXNAME=<hostname> just switch`
