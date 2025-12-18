# hoo-vm Web Interfaces

Quick access to all web UIs running on hoo (192.168.50.32).

## Service URLs

| Service | URL | Default Credentials | Purpose |
|---------|-----|-------------------|---------|
| **CockroachDB Admin** | http://192.168.50.32:8080 | None (insecure mode) | Database admin, metrics, query inspector |
| **Grafana** | http://192.168.50.32:3000 | admin / admin | Metrics visualization, dashboards |
| **Prometheus** | http://192.168.50.32:9090 | None | Metrics collection, query interface |

## CockroachDB Admin UI

**URL:** http://192.168.50.32:8080

### Features
- **Cluster Overview** - Node status, replication, storage
- **Metrics** - CPU, memory, disk, network graphs
- **Databases** - Table schemas, sizes, indexes
- **SQL Activity** - Query statistics, slow queries
- **Jobs** - Backup, restore, schema change status
- **Advanced Debug** - Ranges, hot ranges, node diagnostics

### Quick Actions
```
/          → Overview dashboard
/#/metrics → Detailed metrics
/#/databases → Database browser
/#/statements → SQL query stats
```

---

## Grafana

**URL:** http://192.168.50.32:3000
**Default:** admin / admin (change on first login)

### Pre-configured
- Prometheus datasource already connected
- Auto-provisioned on startup

### Quick Setup

1. **Import CockroachDB Dashboard:**
   - Click `+` → Import
   - Dashboard ID: `7757` (official CockroachDB dashboard)
   - Select Prometheus datasource
   - Click Import

2. **Import Redis Dashboard:**
   - Dashboard ID: `11835`
   - Select Prometheus datasource
   - Click Import

3. **Import Node Exporter Dashboard:**
   - Dashboard ID: `1860`
   - Select Prometheus datasource
   - Click Import

### Custom Dashboards

Create panels to visualize:
- CockroachDB query latency
- Redis memory usage
- System CPU/memory (from node_exporter)
- Custom application metrics

---

## Prometheus

**URL:** http://192.168.50.32:9090

### Features
- **Graph** - Query and visualize metrics
- **Alerts** - Configure alerting rules
- **Targets** - View scrape targets status
- **Service Discovery** - View discovered targets

### Pre-configured Targets

```
http://localhost:9100  → Node Exporter (system metrics)
http://localhost:9121  → Redis Exporter
http://localhost:8080  → CockroachDB metrics
```

### Useful Queries

**CockroachDB:**
```promql
# Query rate
rate(sql_query_count[5m])

# Storage usage
capacity - capacity_available

# Replication lag
replication_lag_seconds
```

**Redis:**
```promql
# Memory usage
redis_memory_used_bytes

# Connected clients
redis_connected_clients

# Command rate
rate(redis_commands_processed_total[5m])
```

**System:**
```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Disk usage
node_filesystem_avail_bytes
```

---

## Accessing Remotely

### SSH Tunnel (Secure)

```bash
# Forward all ports
ssh -L 8080:localhost:8080 \
    -L 3000:localhost:3000 \
    -L 9090:localhost:9090 \
    sysdsqr@192.168.50.32

# Then access locally:
http://localhost:8080  → CockroachDB
http://localhost:3000  → Grafana
http://localhost:9090  → Prometheus
```

### Direct Access (Firewall Open)

All ports are open on the firewall:
- Port 26257 (CockroachDB SQL)
- Port 8080 (CockroachDB Admin)
- Port 3000 (Grafana)
- Port 9090 (Prometheus)

Access directly via: `http://192.168.50.32:<port>`

---

## Quick Health Check

```bash
# Check all services are responding
curl -f http://192.168.50.32:8080/health && echo "CockroachDB OK"
curl -f http://192.168.50.32:3000/api/health && echo "Grafana OK"
curl -f http://192.168.50.32:9090/-/healthy && echo "Prometheus OK"
```

---

## Port Reference

| Port | Service | Protocol |
|------|---------|----------|
| 22 | SSH | TCP |
| 80 | HTTP (unused) | TCP |
| 443 | HTTPS (unused) | TCP |
| 3000 | Grafana | HTTP |
| 3001 | Reserved | TCP |
| 3002 | Reserved | TCP |
| 6379 | Redis | TCP |
| 8080 | CockroachDB Admin UI | HTTP |
| 8081 | Reserved | TCP |
| 9090 | Prometheus | HTTP |
| 9100 | Node Exporter | HTTP |
| 9121 | Redis Exporter | HTTP |
| 26257 | CockroachDB SQL | TCP |

---

## Screenshots Worth Seeing

### CockroachDB Admin UI
- **Overview** - Cluster health at a glance
- **SQL Activity** - Top queries by latency/count
- **Metrics** - Beautiful time-series graphs

### Grafana
- **CockroachDB Dashboard** - Query latency, throughput, replication
- **Redis Dashboard** - Commands/sec, memory, keys
- **Node Dashboard** - CPU, memory, disk I/O

### Prometheus
- **Graph** - Interactive metric visualization
- **Targets** - All exporters status (should be UP)
