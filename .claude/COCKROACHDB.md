# CockroachDB Setup Guide

## Basic Usage

### Connect to SQL Shell

```bash
# Insecure mode (development)
cockroach sql --insecure --host=localhost:26257

# Secure mode (production)
cockroach sql --certs-dir=/etc/cockroach/certs --host=localhost:26257
```

### Admin UI Access

**Insecure mode:**
```
http://192.168.50.32:8080
```

**Secure mode:**
```
https://192.168.50.32:8080
# Requires client certificate in browser
```

---

## Certificate Setup (Secure Mode)

### 1. Create Certificate Directory

```bash
# On the server
sudo mkdir -p /etc/cockroach/certs
sudo mkdir -p /etc/cockroach/my-safe-directory
sudo chown -R cockroach:cockroach /etc/cockroach
```

### 2. Generate CA Certificate

```bash
cockroach cert create-ca \
  --certs-dir=/etc/cockroach/certs \
  --ca-key=/etc/cockroach/my-safe-directory/ca.key
```

### 3. Generate Node Certificate

```bash
# Replace with your actual hostname/IP
cockroach cert create-node \
  localhost \
  $(hostname) \
  192.168.50.32 \
  hoo.dsqr.dev \
  --certs-dir=/etc/cockroach/certs \
  --ca-key=/etc/cockroach/my-safe-directory/ca.key
```

### 4. Generate Root Client Certificate

```bash
cockroach cert create-client \
  root \
  --certs-dir=/etc/cockroach/certs \
  --ca-key=/etc/cockroach/my-safe-directory/ca.key
```

### 5. Set Permissions

```bash
sudo chown -R cockroach:cockroach /etc/cockroach/certs
sudo chmod 700 /etc/cockroach/certs
sudo chmod 600 /etc/cockroach/certs/*.key
```

### 6. Update NixOS Configuration

```nix
services.cockroachdb = {
  enable = true;
  secure = true;
  certsDir = "/etc/cockroach/certs";
  listen.address = "0.0.0.0";
  http.address = "0.0.0.0";
  openFirewall = true;
};
```

### 7. Deploy and Restart

```bash
just switch
sudo systemctl restart cockroachdb
```

---

## User Management

### Create User

```sql
-- Connect as root
cockroach sql --certs-dir=/etc/cockroach/certs

-- Create user with password
CREATE USER myuser WITH PASSWORD 'secure_password';

-- Grant admin privileges
GRANT admin TO myuser;

-- Grant specific database privileges
GRANT ALL ON DATABASE mydb TO myuser;
```

### Change Password

```sql
ALTER USER myuser WITH PASSWORD 'new_password';
```

### List Users

```sql
SHOW USERS;
```

### Generate Client Certificate for User

```bash
cockroach cert create-client \
  myuser \
  --certs-dir=/etc/cockroach/certs \
  --ca-key=/etc/cockroach/my-safe-directory/ca.key
```

---

## Database Management

### Create Database

```sql
CREATE DATABASE mydb;
```

### List Databases

```sql
SHOW DATABASES;
```

### Use Database

```sql
USE mydb;
```

### Drop Database

```sql
DROP DATABASE mydb CASCADE;
```

### Backup Database

```bash
cockroach dump mydb --certs-dir=/etc/cockroach/certs > backup.sql
```

### Restore Database

```bash
cockroach sql --certs-dir=/etc/cockroach/certs < backup.sql
```

---

## Multi-Node Cluster Setup

### Node 1 Configuration

```nix
services.cockroachdb = {
  enable = true;
  singleNode = false;
  secure = true;
  certsDir = "/etc/cockroach/certs";

  listen.address = "0.0.0.0";
  advertiseAddr = "node1.dsqr.dev:26257";
  locality = "region=us-east,zone=a";

  join = [
    "node1.dsqr.dev:26257"
    "node2.dsqr.dev:26257"
    "node3.dsqr.dev:26257"
  ];

  openFirewall = true;
};
```

### Node 2 & 3 Configuration

Same as Node 1, but change `advertiseAddr` to match each node.

### Initialize Cluster (Run Once on Any Node)

```bash
cockroach init --certs-dir=/etc/cockroach/certs --host=node1.dsqr.dev:26257
```

### Check Cluster Status

```bash
cockroach node status --certs-dir=/etc/cockroach/certs --host=localhost:26257
```

---

## Monitoring & Diagnostics

### Check Node Status

```bash
cockroach node status --insecure
```

### View Cluster Ranges

```bash
cockroach node ranges --insecure
```

### View Logs

```bash
journalctl -u cockroachdb -f
```

### Check Metrics (Prometheus Format)

```bash
curl http://localhost:8080/_status/vars
```

---

## Connecting from Applications

### Connection String (Insecure)

```
postgresql://root@localhost:26257/defaultdb?sslmode=disable
```

### Connection String (Secure)

```
postgresql://root@localhost:26257/defaultdb?sslmode=require&sslrootcert=/path/to/ca.crt&sslcert=/path/to/client.root.crt&sslkey=/path/to/client.root.key
```

### TypeScript/Node.js Example

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  port: 26257,
  user: 'root',
  database: 'mydb',
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/etc/cockroach/certs/ca.crt').toString(),
    cert: fs.readFileSync('/etc/cockroach/certs/client.root.crt').toString(),
    key: fs.readFileSync('/etc/cockroach/certs/client.root.key').toString(),
  },
});
```

### Go Example

```go
import (
    "database/sql"
    _ "github.com/lib/pq"
)

connStr := "postgresql://root@localhost:26257/mydb?sslmode=require&sslrootcert=/etc/cockroach/certs/ca.crt&sslcert=/etc/cockroach/certs/client.root.crt&sslkey=/etc/cockroach/certs/client.root.key"
db, err := sql.Open("postgres", connStr)
```

### Python Example

```python
import psycopg2

conn = psycopg2.connect(
    host='localhost',
    port=26257,
    user='root',
    database='mydb',
    sslmode='require',
    sslrootcert='/etc/cockroach/certs/ca.crt',
    sslcert='/etc/cockroach/certs/client.root.crt',
    sslkey='/etc/cockroach/certs/client.root.key'
)
```

---

## Troubleshooting

### Connection Refused

```bash
# Check service is running
systemctl status cockroachdb

# Check firewall
sudo ss -tlnp | grep 26257

# Check logs
journalctl -u cockroachdb -n 50
```

### Certificate Errors

```bash
# Verify certificates exist
ls -la /etc/cockroach/certs

# Check permissions
stat /etc/cockroach/certs/*.key

# Verify certificate validity
cockroach cert list --certs-dir=/etc/cockroach/certs
```

### Performance Issues

```sql
-- Show slow queries
SELECT * FROM crdb_internal.node_queries ORDER BY start DESC LIMIT 10;

-- Show table sizes
SELECT * FROM crdb_internal.table_sizes;

-- Show range info
SHOW RANGES FROM TABLE mytable;
```

---

## Quick Reference

### Essential Commands

```bash
# Connect
cockroach sql --insecure

# Node status
cockroach node status --insecure

# Check health
curl http://localhost:8080/health

# Create database
cockroach sql --insecure -e "CREATE DATABASE mydb;"

# List databases
cockroach sql --insecure -e "SHOW DATABASES;"

# Backup
cockroach dump mydb --insecure > backup.sql

# Restore
cockroach sql --insecure < backup.sql
```
