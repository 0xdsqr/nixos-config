# Infrastructure and application migration roadmap

This is the canonical continuation plan recovered and reconciled on 2026-11-11. When priorities change, update this file instead of relying on task history.

## Completed

### Phases 1-5: Indigo foundation and Dotdev GitOps cutover

The completed work includes the Indigo Kubernetes foundation and the Dotdev deployment cutover:

- Dotdev CI builds, scans, attests, and publishes multi-architecture images.
- A green source CI run triggers a private promotion workflow.
- Promotion updates immutable digest pins in the private `dsqr-labs/deployments` repository through a reviewable PR.
- Argo deploys the merged desired state and reports Dotdev `Synced` and `Healthy`.
- The public infrastructure repository retains reusable Argo/ApplicationSet and Helm integration; private release state remains in `deployments`.
- The shared application Helm chart remains the basis for Dotdev, Labs, and Studio rather than copying a chart per application.
- The legacy Hub-A Dotdev Web deployment path and routing were retired.

## Immediate closeout queue

These are cleanup items rather than separate phases:

1. Rotate the Vault token that appeared in task output.
2. Delete local downloaded GitHub App PEM files after re-verifying their Vault copies.
3. Address the known moderate Dependabot alert in `dsqr-dotdev`.
4. Add private-repository branch protection when the GitHub organization plan supports it; until then, tightly limit direct write access.

## Remaining phases

### Phase 6: Network edge and Wi-Fi migration — current

Move the home lab to AT&T 5 Gbps fiber with minimal downtime while preserving OPNsense and the existing VLAN design.

- Keep the AT&T gateway in IP Passthrough mode.
- Keep the VP2420 temporarily, accepting its 2.5 Gbps ceiling.
- Keep the TL-SG3428X and use its SFP+ cages for the firewall trunk and AP.
- Add a UniFi U7 Pro XGS, trusted SSID, isolated guest VLAN/SSID, and dual-WAN failover.
- Test AT&T in parallel, promote it to primary, soak, and retire the ASUS/old line last.
- Harden the switch and disable Telnet/HTTP.
- Treat a VP2440e/full-10G firewall upgrade as a later subphase.

Full procedure: [Network edge and Wi-Fi migration](runbooks/network-edge-wifi-migration.md)

### Phase 7: Application Redis

Do not connect Indigo applications to the existing `srv-lx-khaos` Redis as currently configured. First audit its consumers, then build a dedicated `srv-lx-redis` NixOS VM unless that audit establishes a better boundary.

1. Reserve the VM identity, Proxmox VM ID, private address, and storage.
2. Declare a roughly 2-vCPU, 4-GiB, 32-64-GiB persistent VM through infrastructure/NixOS.
3. Provide a TLS-only private listener, named ACL users per application, a disabled default user, and exact source firewall rules.
4. Use AOF `everysec`, periodic RDB snapshots, restic backups, and a tested restore.
5. Store separate application credentials, URLs, and CA trust in Vault.
6. Deliver credentials to Indigo through External Secrets.
7. Allow only the intended Dotdev workloads to reach Redis.
8. Integrate Dotdev shared rate limiting, caching, or sessions.
9. Add metrics and alerts for memory, evictions, persistence, connectivity, and backups.
10. Retire Khaos Redis only after its consumer audit proves it is unused.

Start with one durable instance. Add Sentinel or replication only when the availability requirement justifies the operational cost.

### Phase 8: Harbor registry VM

Create a dedicated `srv-lx-harbor` NixOS VM. Harbor owns its internal database and Redis; it must not share the application Redis service.

1. Reserve and declare a VM with approximately 4 vCPU, 8 GiB RAM, a separate OS disk, and roughly 160 GiB of registry storage.
2. Pin the official Harbor release and render `harbor.yml` declaratively with a systemd lifecycle and explicit upgrade procedure.
3. Use HTTPS from day one, encrypted admin credentials, per-workload robot accounts, immutable release artifacts, quotas, and retention.
4. Enable Trivy scanning and registry-side scan policy.
5. Back up registry blobs, Harbor PostgreSQL, configuration, and secrets; prove a restore.
6. Add metrics, logs, disk/certificate alerts, audit retention, and garbage collection.
7. Keep GHCR as the initial build destination and replicate into Harbor.
8. Give Indigo a Harbor pull robot credential through Vault and prove multi-architecture pulls.
9. Update private promotion verification and digest pins to Harbor only after replication and pulls are reliable.
10. Decide later whether a private Actions runner should push directly to Harbor.

### Phase 9: Dotdev hardening

- Complete Redis integration.
- Prove safe scaling beyond one application replica.
- Move image consumption to Harbor after Phase 8 is proven.
- Add application SLOs, alerts, dashboards, resource limits, disruption controls, and operational runbooks.
- Revisit GitHub/Argo promotion hardening without changing the established public-definition/private-release boundary.

### Phase 10: Labs completion and Indigo onboarding

- Finish the Labs application first.
- Use the shared application Helm chart with a separate Labs values overlay and private immutable release pin.
- Reuse the proven CI -> private promotion PR -> Argo flow.
- Add Labs-specific secrets, network access, health checks, limits, monitoring, and rollback documentation.
- Do not copy the Helm chart.

### Phase 11: Studio completion and Indigo onboarding

- Finish Studio first.
- Follow the same shared-chart and private-pin pattern as Dotdev and Labs.
- Add Studio-specific secrets, network access, health checks, limits, monitoring, and rollback documentation.
- Keep application releases independent even though they share chart machinery.

### Phase 12: Final Hub-A application retirement

After Labs and Studio are healthy on Indigo:

- Remove their old workloads and routing from Hub-A.
- Delete orphaned Argo applications and obsolete `dsqr` namespace resources.
- Remove old Secrets, ExternalSecrets, Helm history, Vault KV data, DNS, and firewall exceptions only after dependency audits.
- Preserve unrelated TaskIt/TWT workloads and shared infrastructure.
- Verify that Hub-A no longer carries any DSQR application dependency before final decommissioning.

### Phase 13: Delivery maturity

- Introduce Kargo only if multiple environments and promotion policies make it worthwhile.
- Consider Harbor-native promotion and replication policy.
- Add stronger GitHub protections when the organization plan supports them.
- Automate evidence, policy, and release provenance without weakening the existing PR boundary.

### Phase 14: Disaster recovery validation

- Prove Redis restore into a clean target.
- Prove Harbor database, registry, configuration, and secret restoration.
- Exercise cluster and application recovery from documented backups.
- Record recovery point and recovery time observations.
- Keep recovery procedures versioned and rerun them after material architecture changes.

## Current next action

Complete Phase 6 prerequisites before touching the live network: confirm the AT&T gateway model, export OPNsense and switch configurations, capture the live interface/VLAN map, identify an unused guest VLAN, and purchase the selected AP/injector/SFP+ hardware.
