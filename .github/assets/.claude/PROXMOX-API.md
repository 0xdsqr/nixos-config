# Proxmox API Quick Start

Compact guide for integrating with Proxmox VE API.

## Core Concept

Proxmox exposes everything via REST API at `https://proxmox-host:8006/api2/json`

## Authentication (Use API Tokens)

### Create API User & Token

```bash
# 1. Create user (no shell access)
pveum user add health@pve --comment "Health checks"

# 2. Create role with minimal permissions
pveum role add HealthCheckRole -privs "Sys.Audit,VM.Audit"

# 3. Assign role (cluster-wide)
pveum acl modify / -user health@pve -role HealthCheckRole

# 4. Generate API token
pveum user token add health@pve health-check --comment "monitoring"
# Copy the token secret - shown once!
```

### Use Token in Requests

```bash
curl -k \
  -H "Authorization: PVEAPIToken=health@pve!health-check=SECRET" \
  https://proxmox.dsqr.dev:8006/api2/json/cluster/status
```

---

## Essential Endpoints

| Purpose | Endpoint | Method |
|---------|----------|--------|
| Cluster health | `/cluster/status` | GET |
| Node status | `/nodes/{node}/status` | GET |
| List VMs | `/nodes/{node}/qemu` | GET |
| VM status | `/nodes/{node}/qemu/{vmid}/status/current` | GET |
| Start VM | `/nodes/{node}/qemu/{vmid}/status/start` | POST |
| Stop VM | `/nodes/{node}/qemu/{vmid}/status/stop` | POST |
| Create VM | `/nodes/{node}/qemu` | POST |

---

## Permission Levels

### Read-Only (Health Checks)
```bash
pveum role add ReadOnlyRole -privs "Sys.Audit,VM.Audit"
```

### VM Control (Start/Stop)
```bash
pveum role add VMControlRole -privs "Sys.Audit,VM.Audit,VM.PowerMgmt"
```

### VM Management (Create/Delete)
```bash
pveum role add VMAdminRole -privs \
"Sys.Audit,VM.Audit,VM.Allocate,VM.PowerMgmt,VM.Config.Disk,VM.Config.CPU,VM.Config.Memory,VM.Config.Network"
```

---

## Health Check Example

```typescript
// Bun/Node example
const token = "health@pve!health-check=SECRET";
const base = "https://proxmox.dsqr.dev:8006/api2/json";

const response = await fetch(`${base}/cluster/status`, {
  headers: { Authorization: `PVEAPIToken=${token}` },
  // Ignore self-signed cert (or add to trust store)
  // @ts-ignore
  rejectUnauthorized: false
});

const data = await response.json();
const quorate = data.data.find(n => n.type === 'cluster')?.quorate;

if (quorate !== 1) {
  console.error("Cluster not quorate!");
}
```

---

## Security Best Practices

**Do:**
- Use API tokens (not passwords)
- One token per service
- Least-privilege roles
- Node-scoped ACLs when possible
- Store tokens in SOPS/Vault

**Don't:**
- Use `root@pam` for automation
- Give `Administrator` role
- Reuse UI passwords
- Expose API publicly

---

## Integration with sysdsqr CLI

Future commands you might add:

```typescript
// pkgs/sysdsqr-cli/index.ts
if (command === "proxmox") {
  const subcommand = args[1];

  if (subcommand === "health") {
    // Check cluster/node health
  } else if (subcommand === "vms") {
    // List VMs
  } else if (subcommand === "start") {
    // Start a VM
  }
}
```

Example usage:
```bash
sysdsqr proxmox health
sysdsqr proxmox vms --node hoo
sysdsqr proxmox start --vmid 100
```

---

## Your Proxmox Module

The NixOS module at `modules/nixos/proxmox/default.nix` handles:
- Base Proxmox VE installation
- Network configuration
- Storage setup

API integration is separate - handle in your monitoring/orchestration services.

---

## Next Steps

1. **Create health monitoring service**
   - Periodic checks via API
   - Alert on failures
   - Store metrics (Prometheus/Grafana)

2. **Build VM orchestrator**
   - Create VMs from templates
   - Snapshot/backup automation
   - Resource allocation

3. **Integrate with sysdsqr CLI**
   - Add Proxmox commands
   - Config file for API endpoint/token
   - Pretty output formatting

---

## API Documentation

Full API docs: `https://proxmox-host:8006/pve-docs/api-viewer/index.html`

Or: https://pve.proxmox.com/pve-docs/api-viewer/
