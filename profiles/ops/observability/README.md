# Observability contract

This directory owns DSQR-specific observability policy. Generic NixOS and
nix-darwin mechanics belong in `modules/*`; Kubernetes collectors belong in the
infrastructure GitOps repository; application instrumentation belongs with each
application.

Phase 15A records the live baseline and the destination contract. It makes no
runtime, storage, firewall, service, or deployment changes.

## Signal contract

| Signal | Current backend | Destination | Retention |
|---|---|---|---:|
| Metrics | Prometheus | Mimir | 30 days |
| Logs | Loki | Loki | 14 days |
| Traces | Tempo | Tempo | 14 days |
| Profiles | None | Pyroscope | 14 days |

Every application must emit `service.name`, `service.namespace`,
`service.version`, `service.instance.id`, and
`deployment.environment.name`. Host and Kubernetes telemetry additionally use
`host.name` and `k8s.cluster.name` where applicable.

Routing labels must remain bounded. Request IDs, trace IDs, pod UIDs, raw URLs,
object keys, and user IDs are not Loki index labels. Authorization material,
cookies, tokens, passwords, request or response bodies, URL query strings, raw
SQL, email addresses, user IDs, and IP addresses are omitted, redacted, or
pseudonymized before export.

Successful health and readiness traffic is dropped. Failed health checks,
errors, and slow requests are retained; ordinary successful requests are
sampled.

## Ownership

| Surface | Owner |
|---|---|
| Beacon and host services | Nix |
| Linux and Mac mini host agents | Nix |
| Kubernetes collectors and cluster integrations | GitOps |
| Application telemetry | Application repository |
| Host secrets | agenix or Vault |
| Kubernetes secrets | Vault through External Secrets |

The Kubernetes nodes have one target collector owner: GitOps. Their current
Nix-managed Alloy instances remain in place until the Kubernetes convergence
phase removes them deliberately.

## Host coverage

| Host | Target collector | Role | Additional integrations |
|---|---|---|---|
| `srv-lx-beacon` | NixOS Alloy | Observability | Grafana, metrics, logs, traces, profiles, alerting |
| `srv-lx-gateway` | NixOS Alloy | Gateway | Caddy, Cloudflared |
| `srv-lx-khaos` | NixOS Alloy | Application services | Vault, Temporal, RustFS |
| `srv-lx-knox` | NixOS Alloy | Database | PostgreSQL |
| `srv-lx-mailbox` | NixOS Alloy | Mail | Stalwart |
| `srv-lx-k8s-master-01` | Kubernetes GitOps | Control plane | Kubernetes control-plane signals |
| `srv-lx-k8s-node-01` | Kubernetes GitOps | Worker | Kubernetes node signals |
| `srv-lx-k8s-node-02` | Kubernetes GitOps | Worker | Kubernetes node signals |
| `srv-mini-master` | nix-darwin Alloy | Inference | Exo |
| `srv-mini-node-01` | nix-darwin Alloy | Inference | Exo |
| `dev-mbp-personal` | Disabled | Workstation | None |
| `dev-mbp-stablecore` | Disabled | Workstation | None |

The shared host baseline covers CPU, memory, filesystem, disk, network,
systemd or launchd health, platform logs, and the collector's own health,
queue, WAL, and export metrics. Host-specific integrations extend that
baseline; they do not replace it.

## Baseline captured 2026-07-28

The snapshot below is evidence for later migration decisions, not a desired
configuration:

- Beacon services `alloy`, `grafana`, `loki`, `prometheus`, and `tempo` were
  active.
- Beacon had 4.1 GB RAM, 1.29 GB used, 333 MB swap used, and its 67.3 GB root
  filesystem was 71% used.
- Prometheus had 44,656 active series. The span-metrics duration histogram was
  the largest family at 6,307 series, with 214 distinct `span_name` values.
- Stored data measured 6.65 GB for Prometheus, 2.27 GB for Loki, 349 MB for
  Tempo, 118 MB for Grafana, and 15 MB for Alloy.
- Gateway, Khaos, Knox, Beacon, both Mac minis, and all Kubernetes nodes had
  active host collectors. Mailbox did not.
- Kubernetes ran Alloy 1.11.0 from the 3.x monitoring chart, had no resource
  limits on Alloy containers, and had two kube-state-metrics deployments.

## Migration gates

The following changes belong to later Phase 15 slices and must not be smuggled
into the baseline:

1. Converge package and chart versions.
2. Build the reusable module and `profiles/ops` foundation.
3. Increase Beacon to 8 GB RAM and attach a dedicated 128 GB telemetry disk.
4. Move backend state to the telemetry filesystem before enforcing the 70%
   disk budget.
5. Secure ingestion, add retention, alerting, and collector self-monitoring.
6. Roll out the shared baseline, then remove duplicate Kubernetes collectors.
7. Fix application sampling, privacy, and health-check instrumentation.
8. Introduce Mimir and Pyroscope only after the existing pipeline is stable.

Each migration slice must keep sustained export drops at zero. The initial
guardrails are at most 75,000 active series, 10,000 span-metric series, and 250
distinct span names. Budget increases require an explicit contract change and
new baseline evidence.
