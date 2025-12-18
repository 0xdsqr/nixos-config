# SOPS Quick Start - First VM Setup

**Goal:** Set up SOPS encryption for your first VM (`hoo-vm-x86_64`) with Redis and Grafana secrets.

## Prerequisites Check

```bash
# Verify you're in repo root
pwd  # Should show: /Users/dsqr/workspace/code/nixos-config

# Verify SSH key exists
ls -la ~/.ssh/dsqr_homelab_ed25519
```

---

## Step 1: Install SOPS Tools on Mac

```bash
# Add tools to devShell, then enter it
nix develop

# Verify installation
age --version
sops --version
ssh-to-age --version
```

If tools aren't available, manually install:
```bash
nix-env -iA nixpkgs.age nixpkgs.sops nixpkgs.ssh-to-age
```

---

## Step 2: Generate Admin Age Key (Your Mac)

```bash
# Create SOPS config directory
mkdir -p ~/.config/sops/age

# Generate admin key
age-keygen -o ~/.config/sops/age/keys.txt

# View and SAVE the public key
age-keygen -y ~/.config/sops/age/keys.txt
```

**Output example:**
```
age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

**COPY THIS PUBLIC KEY** - you'll need it in the next step.

---

## Step 3: Create Repository Structure

```bash
# Create directories
mkdir -p secrets/hosts
mkdir -p secrets/shared
mkdir -p keys/hosts

# Create .sops.yaml (replace YOUR_ADMIN_PUBLIC_KEY with the key from step 2)
cat > .sops.yaml << 'SOPS_EOF'
keys:
  # Admin key (your Mac) - REPLACE THIS
  - &admin YOUR_ADMIN_PUBLIC_KEY

  # Host keys (will add after VM boots)
  # - &hoo age1...
  # - &gateway age1...
  # - &dsqr_server age1...

creation_rules:
  # Placeholder - will add per-host rules after generating host keys
  - path_regex: secrets/hosts/.*\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
SOPS_EOF

# Verify file was created
cat .sops.yaml
```

**IMPORTANT:** Edit `.sops.yaml` and replace `YOUR_ADMIN_PUBLIC_KEY` with your actual admin public key from Step 2.

---

## Step 4: Update Flake with sops-nix

```bash
# Add sops-nix to flake inputs (done via Edit tool)
nix flake lock
```

After this guide, you'll run the provided commands to update `flake.nix`.

---

## Step 5: Boot the VM and Generate Host Key

**SSH into your VM** (or use Proxmox console):

```bash
# SSH to VM
ssh sysdsqr@hoo.dsqr.dev

# On the VM, generate host age key
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# View and COPY the public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

**Output example:**
```
age1xyz789abc012def345ghi678jkl901mno234pqr567stu890vwx
```

**COPY THIS HOST PUBLIC KEY** and save it as `hoo` host key.

---

## Step 6: Update .sops.yaml with Host Key

**Back on your Mac**, edit `.sops.yaml`:

```bash
# Edit .sops.yaml to add the host key
```

**Update to:**
```yaml
keys:
  # Admin key (your Mac)
  - &admin age1abc123def456ghi789jkl012mno345pqr678stu901vwx234yz

  # Host keys
  - &hoo age1xyz789abc012def345ghi678jkl901mno234pqr567stu890vwx

creation_rules:
  # hoo-vm-x86_64 secrets
  - path_regex: secrets/hosts/hoo-vm-x86_64\.sops\.ya?ml$
    key_groups:
      - age:
          - *admin
          - *hoo

  # Future hosts...
  # - path_regex: secrets/hosts/gateway-vm-x86_64\.sops\.ya?ml$
  #   key_groups:
  #     - age:
  #         - *admin
  #         - *gateway
```

**Save host public key for reference:**
```bash
echo "age1xyz789abc012def345ghi678jkl901mno234pqr567stu890vwx" > keys/hosts/hoo.pub
```

---

## Step 7: Create First Secret File

```bash
# Create encrypted secret file for hoo
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**In the editor that opens, add:**
```yaml
redis:
  password: "your-secure-redis-password-here"

grafana:
  admin_password: "your-secure-grafana-password-here"
```

**Save and exit.** SOPS will encrypt the values automatically.

**Verify encryption worked:**
```bash
cat secrets/hosts/hoo-vm-x86_64.sops.yaml
```

You should see `ENC[AES256_GCM,...]` for the values but keys remain readable.

---

## Step 8: Configure sops-nix in hoo-vm-x86_64.nix

**Edit** `machines/hoo-vm-x86_64.nix` to add sops configuration at the top after imports:

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
  ];

  # SOPS configuration
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.defaultSopsFile = ../secrets/hosts/hoo-vm-x86_64.sops.yaml;

  # Define secrets
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

  # ... rest of existing config ...
}
```

**Then update the service configurations to use secrets instead of hardcoded passwords.**

**Find this line:**
```nix
services.redis.servers.main.settings.requirepass = "changeme";
```

**Replace with:**
```nix
services.redis.servers.main.settings.requirepass =
  builtins.readFile config.sops.secrets."redis/password".path;
```

**Find this:**
```nix
services.grafana.settings.security.admin_password = "admin";
```

**Replace with:**
```nix
services.grafana.settings.security.admin_password =
  builtins.readFile config.sops.secrets."grafana/admin_password".path;
```

---

## Step 9: Commit Encrypted Secrets

```bash
# Add files to git
git add .sops.yaml secrets/ keys/

# Verify what you're committing (secrets should be encrypted)
git diff --cached secrets/hosts/hoo-vm-x86_64.sops.yaml

# Commit
git commit -m "feat: add SOPS secrets management for hoo-vm-x86_64"
```

---

## Step 10: Deploy to VM

```bash
# From Mac, rebuild the VM
NIXNAME=hoo-vm-x86_64 just switch

# Or SSH to VM and rebuild locally
ssh sysdsqr@hoo.dsqr.dev
cd /path/to/nixos-config
sudo nixos-rebuild switch --flake .#hoo-vm-x86_64
```

---

## Step 11: Verify Secrets Work

**On the VM:**

```bash
# Check secret files were created
sudo ls -la /run/secrets/
sudo ls -la /run/secrets/redis/
sudo ls -la /run/secrets/grafana/

# Verify Redis is using the secret
sudo systemctl status redis-main.service

# Test Redis authentication (should require password)
redis-cli ping
# Should get: (error) NOAUTH Authentication required.

redis-cli -a $(sudo cat /run/secrets/redis/password) ping
# Should get: PONG

# Check Grafana admin password (if needed)
sudo cat /run/secrets/grafana/admin_password
```

---

## Done!

You now have:
- ✅ Admin age key for managing all secrets
- ✅ Host age key on hoo VM
- ✅ Encrypted secrets in git
- ✅ Services using secrets at runtime
- ✅ Secrets stored in memory-only tmpfs

---

## Next Steps

**Add more VMs:** Use the same pattern for `gateway-vm-x86_64` and `dsqr-server-vm-x86_64`:
1. SSH to VM and generate host key
2. Add host key to `.sops.yaml`
3. Create `secrets/hosts/<hostname>.sops.yaml`
4. Configure sops in machine config
5. Rebuild

**Edit secrets:**
```bash
sops secrets/hosts/hoo-vm-x86_64.sops.yaml
```

**Rotate keys:**
```bash
# After changing a key in .sops.yaml
sops updatekeys secrets/hosts/hoo-vm-x86_64.sops.yaml
```

---

## Troubleshooting

**"no keys could decrypt the data"**
- Verify `~/.config/sops/age/keys.txt` exists on Mac
- Check the admin key in `.sops.yaml` matches

**"cannot stat '/var/lib/sops-nix/key.txt'"**
- Generate host key on VM first (Step 5)

**Redis/Grafana still using old password**
- Verify you updated the service configuration to use `config.sops.secrets` paths
- Check systemd logs: `journalctl -u redis-main.service -f`
