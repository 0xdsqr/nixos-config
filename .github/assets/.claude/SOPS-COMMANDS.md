# SOPS Setup - Compact Commands

**Setting up SOPS for `hoo-vm-x86_64` VM with encrypted Redis and Grafana passwords.**

---

## On Your Mac (Admin Setup)

```bash
# 1. Enter dev shell to get sops/age tools
cd ~/workspace/code/nixos-config
nix flake lock
nix develop

# 2. Generate admin age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. View and SAVE your admin public key
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1abc123...xyz (COPY THIS)

# 4. Create repo structure
mkdir -p secrets/hosts secrets/shared keys/hosts

# 5. Create .sops.yaml (replace YOUR_ADMIN_KEY with key from step 3)
cat > .sops.yaml << 'EOF'
keys:
  - &admin YOUR_ADMIN_KEY

creation_rules:
  - path_regex: secrets/hosts/.*\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
EOF

# Edit .sops.yaml and replace YOUR_ADMIN_KEY with your actual key from step 3
```

---

## On the VM (Host Key Generation)

```bash
# 6. SSH to your VM
ssh sysdsqr@hoo.dsqr.dev

# 7. Install age on VM (if not already present)
sudo nix-env -iA nixos.age

# 8. Generate host age key
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# 9. View and COPY host public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1xyz789...abc (COPY THIS)

# 10. Exit VM
exit
```

---

## Back on Mac (Configure Encryption)

```bash
# 11. Update .sops.yaml with host key (replace HOST_KEY with key from step 9)
cat > .sops.yaml << 'EOF'
keys:
  - &admin YOUR_ADMIN_KEY
  - &hoo HOST_KEY

creation_rules:
  - path_regex: secrets/hosts/hoo-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *hoo
EOF

# 12. Save host public key for reference
echo "HOST_KEY" > keys/hosts/hoo.pub

# 13. Create encrypted secret file (will open editor)
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**In the editor, add:**
```yaml
redis:
  password: "your-secure-redis-password"

grafana:
  admin_password: "your-secure-grafana-password"

prometheus:
  redis_exporter_password: "your-secure-redis-password"
```

**Save and exit. SOPS encrypts automatically.**

```bash
# 14. Verify encryption worked (should see ENC[...])
cat secrets/hosts/hoo-vm-x86_64.sops.yaml
```

---

## Configure NixOS (Wire Secrets)

```bash
# 15. Edit hoo-vm-x86_64.nix to add sops configuration
# Add this after the imports block:
```

**Add to `machines/hoo-vm-x86_64.nix`:**

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
    inputs.sops-nix.nixosModules.sops  # ADD THIS LINE
  ];

  # SOPS configuration - ADD THIS SECTION
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.defaultSopsFile = ../secrets/hosts/hoo-vm-x86_64.sops.yaml;

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

  # ... rest of config ...

  # UPDATE Redis configuration (find this section and change it)
  services.redis.servers.main.settings.requirepass =
    builtins.readFile config.sops.secrets."redis/password".path;

  # UPDATE Grafana configuration (find this section and change it)
  services.grafana.settings.security.admin_password =
    builtins.readFile config.sops.secrets."grafana/admin_password".path;

  # UPDATE Prometheus exporter (find this section and change it)
  services.prometheus.exporters.redis.extraFlags = [
    "--redis.password=$(cat ${config.sops.secrets."redis/password".path})"
  ];
}
```

---

## Deploy and Verify

```bash
# 16. Commit encrypted secrets to git
git add .sops.yaml secrets/ keys/ machines/hoo-vm-x86_64.nix flake.nix flake.lock devshell.nix
git commit -m "feat: add SOPS secrets management"

# 17. Deploy to VM
NIXNAME=hoo-vm-x86_64 just switch
```

---

## Verify on VM

```bash
# 18. SSH to VM and verify
ssh sysdsqr@hoo.dsqr.dev

# Check secret files exist
sudo ls -la /run/secrets/

# Test Redis with new password
redis-cli -a $(sudo cat /run/secrets/redis/password) ping
# Should return: PONG

# Check Grafana logs
sudo journalctl -u grafana.service -f

# Verify services are running
sudo systemctl status redis-main.service
sudo systemctl status grafana.service
```

---

## Done!

Your secrets are now:
- ✅ Encrypted in git
- ✅ Decrypted at activation time
- ✅ Stored in memory-only tmpfs (/run/secrets)
- ✅ Accessible only to service users
- ✅ Rotatable via `sops updatekeys`

---

## Common Commands

**Edit secrets:**
```bash
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**View decrypted (without editing):**
```bash
sops -d secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**Check which keys can decrypt:**
```bash
sops filestatus secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**Rotate keys after changing .sops.yaml:**
```bash
sops updatekeys secrets/hosts/hoo-vm-x86_64.sops.yaml
```

---

## Add Another VM (Quick Reference)

```bash
# On VM
ssh sysdsqr@newvm.dsqr.dev
sudo mkdir -p /var/lib/sops-nix && sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo age-keygen -y /var/lib/sops-nix/key.txt  # Copy public key

# On Mac
# Add key to .sops.yaml
# Add creation rule for new host
sops secrets/hosts/newvm.sops.yaml  # Create secrets
# Update machines/newvm.nix with sops config
NIXNAME=newvm just switch
```
