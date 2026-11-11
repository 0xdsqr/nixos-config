# Network edge and Wi-Fi migration

Status: planned; hardware selection is complete, implementation has not started.

This runbook moves the home-lab edge to the AT&T 5 Gbps fiber service with minimal downtime, preserves OPNsense and the existing VLAN design, and replaces router-provided Wi-Fi with a VLAN-aware UniFi access point.

## Confirmed design

```text
AT&T fiber
  -> AT&T gateway (IP Passthrough; Wi-Fi disabled after cutover)
  -> Protectli VP2420 running OPNsense (2.5 Gbps limit for now)
  -> TP-Link TL-SG3428X
       -> existing wired VLANs
       -> UniFi U7 Pro XGS
            -> trusted SSID
            -> isolated guest SSID
```

- Keep the AT&T gateway. Do not replace it with a UniFi gateway.
- Keep OPNsense as the router, firewall, DHCP/DNS boundary, VLAN gateway, and dual-WAN controller.
- Keep the TL-SG3428X. It has 24 one-gigabit RJ45 ports and four 10 Gbps SFP+ cages, but no PoE.
- Keep the VP2420 initially. Its four RJ45 interfaces support 2.5 Gbps, so it will limit the 5 Gbps service to roughly 2.2-2.5 Gbps.
- Use one U7 Pro XGS initially. It can broadcast both trusted and guest SSIDs. Add another wired AP only if a coverage survey shows it is necessary.
- Preserve the declared management, client, server, gateway/DMZ, and Indigo VLANs. Select a new unused VLAN ID for guests only after auditing the live configuration.

## Hardware

Prices are planning figures recorded in November 2026; verify them before purchasing.

1. UniFi U7 Pro XGS (`U7-Pro-XGS`)
   - Amazon search: <https://www.amazon.com/s?k=Ubiquiti+U7+Pro+XGS>
   - Official store: <https://store.ui.com/us/en/category/wifi-flagship/products/u7-pro-xgs>
   - Review: <https://www.rtings.com/router/reviews/unifi/u7-pro-xgs-wired-backhaul>
2. Ubiquiti 10G PoE++ injector (`UACC-PoE++-10G`)
   - Amazon search: <https://www.amazon.com/s?k=UACC-PoE%2B%2B-10G>
3. Two TP-Link `TL-SM5310-T` multigig copper SFP+ modules
   - Amazon: <https://www.amazon.com/TP-Link-TL-SM5310-T-10GBase-T-Transceiver-Compatibility/dp/B0B12N5SJN>
   - Specifications: <https://www.tp-link.com/us/business-networking/accessory/tl-sm5310-t/v1/>
4. Cat6A patch cables
   - Amazon search: <https://www.amazon.com/s?k=Cat6A+patch+cable+10Gb>

Expected total: approximately $450-$500 before tax. Prefer the official Ubiquiti store if an Amazon third-party seller charges substantially more than the official price.

The four 10 Gbps switch ports are SFP+ cages, not RJ45 ports. The two `TL-SM5310-T` modules provide these paths:

```text
VP2420 LAN at 2.5 Gbps
  -> Cat6A
  -> TL-SM5310-T in TL-SG3428X SFP+ cage

TL-SG3428X SFP+ cage
  -> TL-SM5310-T
  -> Cat6A
  -> Ubiquiti 10G PoE++ injector
  -> Cat6A carrying data and power
  -> U7 Pro XGS
```

Use separated SFP+ cages when possible because 10GBase-T modules run hot.

## Required facts before changing anything

- Exact AT&T gateway model, expected to be a BGW320 variant.
- Current OPNsense `Interfaces -> Assignments` mapping and an unused VP2420 port.
- Current TL-SG3428X VLAN membership, PVID, and Protectli-facing port.
- A verified unused VLAN ID and subnet for the guest network.
- Exact switch hardware region and supported sequential firmware upgrade path.
- A central, wired AP mounting location.

Do not guess any of these values during the cutover.

## Migration procedure

### 1. Back up and inventory

1. Export an encrypted OPNsense configuration backup.
2. Export the TL-SG3428X configuration.
3. Export or screenshot the ASUS configuration.
4. Photograph and label every cable.
5. Record interface assignments, switch VLAN/PVID configuration, DHCP ranges, reservations, DNS, NAT, Cloudflare Tunnels, Tailscale, and public-IP allowlists.
6. Leave the old Internet service and existing Wi-Fi operational.

### 2. Maintain and harden the switch

Perform this as a separate maintenance window with local or console recovery available.

1. Confirm hardware revision and region.
2. Follow TP-Link's required sequential path to the correct stable firmware; do not flash an unverified image or skip required versions.
3. Verify that the configuration survived the reboot.
4. Enable and test HTTPS and SSHv2.
5. Disable HTTP and Telnet.
6. Restrict management to the management VLAN.
7. Use SNMPv3 or tightly restrict SNMP with ACLs.
8. Enable RSTP only after confirming the physical topology has no unintended loops.
9. Leave jumbo frames disabled unless the entire path is deliberately configured for them.

The firmware reboot is the main planned LAN outage.

### 3. Move the Protectli trunk to 2.5 Gbps

1. Install the first `TL-SM5310-T` in an unused SFP+ cage.
2. Copy the existing Protectli-facing port's VLAN membership and PVID exactly.
3. Move the VP2420 LAN cable to the module.
4. Confirm that the link negotiates at 2.5 Gbps.
5. Verify all existing VLANs and critical services before continuing.

Expected interruption: less than a minute if the port configuration is correct.

### 4. Create the guest network in OPNsense

1. Create a new guest VLAN using the audited unused VLAN ID.
2. Add its OPNsense interface, subnet, and DHCP service.
3. Permit only the firewall services guests require, normally DHCP, DNS, and NTP.
4. Deny access to management, trusted clients, servers, gateway/DMZ, Indigo, and all other private networks.
5. Permit Internet access.
6. Apply equivalent IPv6 isolation or disable guest IPv6 initially.
7. Enable wireless client isolation for the guest SSID.

### 5. Install UniFi and the AP

1. Run UniFi Network Server on a stable internal NixOS or Proxmox host. The controller manages the AP only; the TP-Link switch remains independently managed.
2. Install the second `TL-SM5310-T` in a separated SFP+ cage.
3. Configure the AP-facing switch port with only the management, trusted-client, and guest VLANs.
4. Connect switch module -> injector Data -> injector PoE -> U7 Pro XGS.
5. Adopt and update the AP.
6. Place AP management on the management VLAN.
7. Create temporary trusted and guest SSIDs mapped to their respective VLANs.
8. Verify that trusted clients reach allowed internal services and the Internet.
9. Verify that guest clients reach the Internet but cannot reach any private network, management interface, or another guest client.

Keep the ASUS and AT&T Wi-Fi enabled until these tests pass.

### 6. Add AT&T as a secondary WAN

1. Assign an unused VP2420 interface as `WAN_ATT` using DHCP and record its MAC address.
2. Connect the AT&T gateway's blue multigig port to `WAN_ATT` and verify a 2.5 Gbps link.
3. Configure AT&T IP Passthrough with `DHCPS-fixed` for the `WAN_ATT` MAC.
4. Renew or reboot as required and verify the OPNsense WAN address.
5. Policy-route one test client through AT&T.
6. Test throughput, DNS, IPv4, Cloudflare Tunnels, Tailscale, VPNs, Kubernetes ingress, NAT, outbound services, and public-IP allowlists.
7. Treat IPv6 as a separate validation step after IPv4 is stable.
8. Create an OPNsense gateway group with the old WAN at Tier 1 and AT&T at Tier 2.
9. Simulate failure of the old WAN and verify automatic failover, then restore it.

### 7. Cut over

1. Promote AT&T to Tier 1 and move the old WAN to Tier 2.
2. Revalidate all critical services.
3. Move trusted clients to UniFi. Reuse the old trusted SSID and password only after the new AP is proven.
4. Keep the guest SSID separate.
5. Disable AT&T Wi-Fi and WPS.
6. Disable ASUS Wi-Fi, but keep the old line and ASUS available during the soak period.

Expected WAN interruption: seconds to a few minutes. Internal VLAN addresses do not change.

### 8. Soak and retire the old path

1. Run for approximately seven days with the old WAN retained as failover.
2. Monitor gateway loss/latency, Wi-Fi stability, DNS, Cloudflare Tunnels, Tailscale, Kubernetes ingress, and guest isolation.
3. Export fresh OPNsense and switch backups.
4. Document the final cable map, port assignments, VLANs, and recovery procedure.
5. Remove obsolete ASUS and old-WAN rules only after the soak succeeds.
6. Cancel the old service last.

## Rollback

- Before cutover, leave the old WAN as Tier 1 and old Wi-Fi enabled.
- If the AT&T path fails after cutover, restore the old WAN to Tier 1.
- If UniFi fails, re-enable or continue using the ASUS Wi-Fi.
- If the new SFP+ trunk fails, restore the VP2420 cable to the original switch port and its saved configuration.

## Later 10 Gbps edge upgrade

Replace the VP2420 only when full 5 Gbps WAN throughput is required. A likely layout is:

```text
AT&T gateway
  -> multigig copper SFP+ module
  -> Protectli VP2440e WAN

Protectli VP2440e LAN SFP+
  -> SFP+ DAC
  -> TL-SG3428X

TL-SG3428X
  -> existing 10G copper module and PoE++ injector
  -> U7 Pro XGS
```

The AP and current switch are already suitable for this future path. Replace the switch only if multiple wired multigig or PoE devices require more ports.
