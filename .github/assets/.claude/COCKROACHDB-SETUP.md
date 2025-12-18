# CockroachDB Setup Guide

Quick guide for setting up CockroachDB in your NixOS homelab using the custom module.

## Overview

The CockroachDB module at `modules/nixos/cockroachdb.nix` provides:
- Declarative NixOS service configuration
- Single-node or cluster mode
- Secure (TLS) or insecure mode
- Systemd service management

---

## Basic Configuration

### Single Node (Development)

```nix
# In your NixOS configuration
{
  imports = [
    inputs.dsqr-nix.nixosModules.cockroachdb
  ];

  services.cockroachdb = {
    enable = true;
    singleNode = true;
    secure = false;  # Insecure mode for development

    listen = {
      address = "0.0.0.0";
      port = 26257;
    };

    http = {
      address = "0.0.0.0";
      port = 8080;
    };
  };

  # Open firewall
  networking.firewall.allowedTCPPorts = [ 26257 8080 ];
}
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .
```

Access the UI: `http://your-host:8080`

---

## Secure Mode (Production)

### 1. Generate Certificates

CockroachDB uses mutual TLS. You need to generate certs **before** enabling the service.

#### Option A: Using cockroach CLI (Recommended)

```bash
# Install cockroach temporarily
nix shell nixpkgs#cockroachdb

# Create certs directory
mkdir -p /var/lib/cockroachdb/certs
cd /var/lib/cockroachdb

# Generate CA certificate
cockroach cert create-ca \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Generate node certificate (for this host)
cockroach cert create-node \
  localhost \
  $(hostname) \
  $(hostname -f) \
  YOUR_IP_ADDRESS \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Generate client certificate (for root user)
cockroach cert create-client \
  root \
  --certs-dir=certs \
  --ca-key=my-safe-directory/ca.key

# Set permissions
chmod 0700 certs
chown -R cockroachdb:cockroachdb certs

# Secure the CA key (store offline)
chmod 0400 my-safe-directory/ca.key
```

**Important**: Store `ca.key` securely - you'll need it to add nodes or create client certs later.

#### Option B: Using NixOS SOPS/agenix

If you manage secrets with SOPS or agenix, store the certs there:

```nix
{
  # Example with SOPS
  sops.secrets."cockroachdb/ca.crt" = {
    path = "/var/lib/cockroachdb/certs/ca.crt";
    owner = "cockroachdb";
    group = "cockroachdb";
    mode = "0400";
  };

  sops.secrets."cockroachdb/node.crt" = {
    path = "/var/lib/cockroachdb/certs/node.crt";
    owner = "cockroachdb";
    group = "cockroachdb";
    mode = "0400";
  };

  sops.secrets."cockroachdb/node.key" = {
    path = "/var/lib/cockroachdb/certs/node.key";
    owner = "cockroachdb";
    group = "cockroachdb";
    mode = "0400";
  };

  sops.secrets."cockroachdb/client.root.crt" = {
    path = "/var/lib/cockroachdb/certs/client.root.crt";
    owner = "cockroachdb";
    group = "cockroachdb";
    mode = "0400";
  };

  sops.secrets."cockroachdb/client.root.key" = {
    path = "/var/lib/cockroachdb/certs/client.root.key";
    owner = "cockroachdb";
    group = "cockroachdb";
    mode = "0400";
  };
}
```

---

### 2. Enable Secure Mode

```nix
{
  services.cockroachdb = {
    enable = true;
    singleNode = true;  # or false for cluster
    secure = true;      # Enable TLS
    certsDir = "/var/lib/cockroachdb/certs";

    listen = {
      address = "0.0.0.0";
      port = 26257;
    };

    http = {
      address = "0.0.0.0";
      port = 8080;
    };
  };

  networking.firewall.allowedTCPPorts = [ 26257 8080 ];
}
```

---

## Cluster Mode (Multi-Node)

For a 3-node cluster across your homelab:

### Node 1 (Initial Node)

```nix
{
  services.cockroachdb = {
    enable = true;
    singleNode = false;
    secure = true;

    # Initialize cluster on first boot
    initialize = true;

    # Join other nodes (list all nodes)
    join = [
      "node1.dsqr.dev:26257"
      "node2.dsqr.dev:26257"
      "node3.dsqr.dev:26257"
    ];

    advertiseAddr = "node1.dsqr.dev:26257";
    locality = "region=homelab,datacenter=rack1";
  };
}
```

### Node 2 & 3

```nix
{
  services.cockroachdb = {
    enable = true;
    singleNode = false;
    secure = true;
    initialize = false;  # Only initialize on one node

    join = [
      "node1.dsqr.dev:26257"
      "node2.dsqr.dev:26257"
      "node3.dsqr.dev:26257"
    ];

    advertiseAddr = "node2.dsqr.dev:26257";  # Change per node
    locality = "region=homelab,datacenter=rack1";
  };
}
```

**Important**: All nodes need the same CA certificate but unique node certificates.

---

## Connecting to CockroachDB

### Using cockroach CLI

```bash
# Insecure mode
cockroach sql --insecure --host=localhost:26257

# Secure mode
cockroach sql \
  --certs-dir=/var/lib/cockroachdb/certs \
  --host=localhost:26257
```

### Using psql (PostgreSQL compatible)

```bash
# Insecure mode
psql "postgresql://root@localhost:26257/defaultdb?sslmode=disable"

# Secure mode
psql "postgresql://root@localhost:26257/defaultdb?sslmode=require&sslrootcert=/var/lib/cockroachdb/certs/ca.crt&sslcert=/var/lib/cockroachdb/certs/client.root.crt&sslkey=/var/lib/cockroachdb/certs/client.root.key"
```

### From Application Code

```typescript
// TypeScript with node-postgres
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  port: 26257,
  user: 'root',
  database: 'defaultdb',
  ssl: {
    ca: fs.readFileSync('/var/lib/cockroachdb/certs/ca.crt'),
    cert: fs.readFileSync('/var/lib/cockroachdb/certs/client.root.crt'),
    key: fs.readFileSync('/var/lib/cockroachdb/certs/client.root.key'),
  },
});
```

---

## Module Options Reference

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable CockroachDB service |
| `singleNode` | `false` | Run in single-node mode |
| `secure` | `false` | Enable TLS (requires certs) |
| `certsDir` | `${dataDir}/certs` | Certificate directory |
| `dataDir` | `/var/lib/cockroachdb` | Data directory |
| `listen.address` | `"127.0.0.1"` | SQL listen address |
| `listen.port` | `26257` | SQL port |
| `http.address` | `"127.0.0.1"` | HTTP UI address |
| `http.port` | `8080` | HTTP UI port |
| `join` | `[]` | Cluster join addresses |
| `initialize` | `false` | Initialize cluster on first boot |
| `advertiseAddr` | `null` | Advertise address for clustering |
| `locality` | `null` | Locality for replica placement |
| `cache` | `"25%"` | Cache size |
| `maxSqlMemory` | `"25%"` | Max SQL memory |

---

## Common Tasks

### Create Database

```sql
CREATE DATABASE myapp;
```

### Create User

```sql
CREATE USER myapp WITH PASSWORD 'secure-password';
GRANT ALL ON DATABASE myapp TO myapp;
```

### Backup Database

```bash
# Insecure mode
cockroach dump myapp --insecure > backup.sql

# Secure mode
cockroach dump myapp \
  --certs-dir=/var/lib/cockroachdb/certs \
  --host=localhost:26257 > backup.sql
```

### Check Cluster Health

```bash
cockroach node status --certs-dir=/var/lib/cockroachdb/certs
```

---

## Troubleshooting

### Check Service Status

```bash
systemctl status cockroachdb
journalctl -u cockroachdb -f
```

### Certificate Issues

```
error: problem with CA certificate
```

**Solution**: Verify cert permissions:
```bash
ls -la /var/lib/cockroachdb/certs
# Should be owned by cockroachdb:cockroachdb
# Should be mode 0700 for directory, 0400 for files
```

### Connection Refused

```
connection refused at :26257
```

**Check**:
1. Service running: `systemctl status cockroachdb`
2. Firewall: `nix-shell -p nmap --run "nmap -p 26257 localhost"`
3. Listen address: Check `listen.address` in config

### Cluster Init Failed

```
ERROR: could not initialize cluster
```

**Solution**: Only set `initialize = true` on ONE node, not all nodes.

---

## Integration with sysdsqr CLI

Future commands:

```typescript
// pkgs/sysdsqr-cli/index.ts
if (command === "db") {
  const subcommand = args[1];

  if (subcommand === "status") {
    // Check CockroachDB cluster health
  } else if (subcommand === "backup") {
    // Trigger backup
  } else if (subcommand === "create-user") {
    // Create database user
  }
}
```

---

## Should the Module Handle Certs?

**Current approach (correct):**
- Module manages service configuration
- User generates certs manually
- Module ensures correct permissions

**Why not auto-generate?**
- Certs need to be distributed across nodes
- CA key must be stored securely offline
- Certificate rotation requires manual steps
- Security best practice: manual cert management

**Future enhancement:**
Could add a `services.cockroachdb.generateInsecureCerts = true` option for development that auto-generates certs at service start (similar to how PostgreSQL does it).

---

## Best Practices

1. **Always use secure mode in production**
2. **Store CA key offline** (not on the server)
3. **Use SOPS/agenix for cert management** in NixOS
4. **Back up your data directory** regularly
5. **Use locality tags** for multi-datacenter setups
6. **Monitor the web UI** for cluster health
7. **Test failover** before relying on cluster mode

---

## Resources

- Official docs: https://www.cockroachlabs.com/docs/
- Cert creation: https://www.cockroachlabs.com/docs/stable/cockroach-cert.html
- Module source: `modules/nixos/cockroachdb.nix`
