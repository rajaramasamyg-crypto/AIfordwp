# Root Cause Analysis (RCA): Floor 3 Domain Controller Connectivity Failure After DNS Migration

## Incident Summary
- Incident type: Endpoint startup domain connectivity failure
- Primary affected endpoint: DESKTOP-FB031
- Broader scope: 3 of 4 Finance OU workstations on the affected subnet
- Observation window: 2024-03-15 07:40 to 07:55
- Comparison endpoint: DESKTOP-FB029 (same OU, unaffected)
- Current status: Root cause identified; remediation required on DHCP scope and affected clients

## Executive Summary
During the startup window, DESKTOP-FB031 failed to contact a FINBRIDGE domain controller and could not process Group Policy. The failure began before the endpoint had a valid DHCP lease and continued after DHCP assigned an outdated DNS server, 10.10.3.250, which had been decommissioned earlier in the migration wave. The unaffected comparison machine, DESKTOP-FB029, received the correct replacement DNS server, 10.10.0.10, and processed Group Policy successfully.

The evidence supports a subnet-specific DHCP misconfiguration rather than a domain controller outage or workstation-local defect. The Floor 3 DHCP scope still referenced the retired DNS server, causing affected clients to fail DNS resolution for FINBRIDGE-DC01.finbridge.local during startup. One workstation remained unaffected only because it had been manually configured with the new DNS server before the migration.

## Scope and Impact
- Scope: 3 of 4 machines in the affected Finance OU segment were impacted during startup
- User impact: Delayed or failed domain authentication and Group Policy processing at logon
- Technical impact: Netlogon secure channel setup failed and SYSVOL could not be reached
- Business impact: Users on affected endpoints were exposed to login delays, missing policy application, and potential access or configuration inconsistencies

## Supporting Evidence

### DESKTOP-FB031 Event Sequence
1. 07:40:08 - Netlogon Event 5719
   - The computer could not establish a secure channel to domain FINBRIDGE because no domain controller was available.
   - DNS query for FINBRIDGE-DC01.finbridge.local returned no response.

2. 07:40:09 - GroupPolicy Event 1058
   - Group Policy could not access `\\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini`.
   - Error code: 0x3, path not found.

3. 07:40:10 - GroupPolicy Event 1030
   - The client could not query the list of applicable Group Policy objects.

4. 07:40:12 - GroupPolicy Event 1129
   - Group Policy processing failed because there was no network connectivity to a domain controller.

5. 07:41:05 - DNS Client Event 1014
   - Name resolution for FINBRIDGE-DC01.finbridge.local timed out.
   - None of the configured DNS servers responded.

6. 07:42:18 - DHCP Client Event 50036
   - The host received IP address 10.10.3.144.
   - DHCP assigned DNS server 10.10.3.250.
   - 10.10.3.250 had been decommissioned at 02:00 during the migration wave.

7. 07:44:01 - GroupPolicy Event 1129
   - Group Policy failed again because domain controller connectivity was still unavailable.

### Unaffected Comparison: DESKTOP-FB029
1. 07:40:05 - DHCP Client Event 50036
   - The host received IP address 10.10.3.141.
   - DNS server assigned: 10.10.0.10, the correct post-migration DNS server.

2. 07:40:11 - GroupPolicy Event 1500
   - Group Policy processed successfully.

### DHCP Server Comparison
- FB055-FB057 received DNS server 172.16.5.5, a decommissioned Floor 3 local DNS server.
- FB058 received DNS server 10.10.0.10, the correct central DNS server.
- FB058 had been manually preconfigured before the migration and therefore was not affected.

## Timeline
1. 07:40:08 - DESKTOP-FB031 fails Netlogon secure channel setup because FINBRIDGE-DC01 cannot be resolved.
2. 07:40:09 to 07:40:12 - Group Policy fails repeatedly because SYSVOL and the DC are unreachable.
3. 07:41:05 - DNS timeout confirms name resolution failure rather than a simple SMB path issue.
4. 07:42:18 - DHCP assigns a lease containing the retired DNS server 10.10.3.250.
5. 07:44:01 - Group Policy fails again, consistent with persistent bad DNS assignment.
6. 07:40:05 to 07:40:11 on DESKTOP-FB029 - Comparison host receives 10.10.0.10 and completes Group Policy successfully.
7. Post-comparison - DHCP logs show the affected Floor 3 scope still referenced decommissioned DNS infrastructure.

## Technical Interpretation
- Netlogon 5719, GroupPolicy 1058/1030/1129, and DNS Client 1014 all align with one dependency failure: the client could not resolve or reach a domain controller during startup.
- The later DHCP event is decisive because it shows the endpoint was assigned a DNS server that had already been retired during the migration.
- The unaffected comparison host disproves a general FINBRIDGE domain controller outage. If the DC were unavailable globally, DESKTOP-FB029 would also have failed Group Policy.
- The mixed outcome across similar machines is explained by configuration source: machines inheriting the stale DHCP scope failed, while the manually preconfigured machine using 10.10.0.10 succeeded.

## Root Cause Statement
The incident was caused by an outdated DHCP scope configuration on the Floor 3 subnet that continued to assign a decommissioned DNS server after the DNS migration. As a result, affected workstations could not resolve FINBRIDGE-DC01.finbridge.local during startup, which prevented domain secure channel establishment and caused Group Policy processing failures.

## Five Whys Analysis

### Problem
Why did DESKTOP-FB031 and other Floor 3 workstations fail to process Group Policy at startup?
- Because they could not contact a FINBRIDGE domain controller.

### Why 1
Why could they not contact a domain controller?
- Because DNS resolution for FINBRIDGE-DC01.finbridge.local failed.
- Evidence: Netlogon 5719 and DNS Client 1014.

### Why 2
Why did DNS resolution fail?
- Because the clients were configured with a DNS server that did not respond.
- Evidence: DHCP Client 50036 assigned 10.10.3.250, which was already decommissioned.

### Why 3
Why were clients assigned the retired DNS server?
- Because the Floor 3 DHCP scope still referenced the old DNS server after the migration wave.
- Evidence: DHCP comparison data shows affected machines inherited stale DNS settings, while the manually configured machine did not.

### Why 4
Why was the DHCP scope not updated during the migration?
- Because the DNS infrastructure migration did not fully propagate to all dependent network services before the startup window.

### Why 5
Why did the incomplete migration affect only some machines?
- Because only machines depending on the stale DHCP scope inherited the bad DNS configuration; the manually preconfigured host bypassed the faulty scope.

## Recommended Remediation
1. Update the Floor 3 DHCP scope so that option 006 points to 10.10.0.10 and remove references to all retired DNS servers.
2. Force DHCP lease renewal on affected endpoints and confirm they receive the new DNS server.
3. Run `ipconfig /flushdns` and `gpupdate /force` on affected endpoints after lease renewal.
4. Validate domain controller name resolution with `nslookup FINBRIDGE-DC01.finbridge.local` and confirm SYSVOL access.
5. Review all migration-wave DHCP scopes for stale DNS references to prevent recurrence on additional subnets.

## Preventive Actions
1. Add a pre-cutover dependency checklist that includes DHCP option validation for every subnet using migrated DNS services.
2. Add a post-change verification step that samples multiple clients per subnet to confirm correct DNS assignment.
3. Maintain an explicit migration rollback and exception register for hosts that were manually preconfigured.
4. Add monitoring or alerting for DHCP scopes that reference decommissioned infrastructure addresses.
5. Require a startup-path validation test after network service migrations: DHCP lease, DNS resolution, Netlogon, and Group Policy processing.

## Verification Criteria
- Affected clients receive DNS server 10.10.0.10 from DHCP.
- `nslookup FINBRIDGE-DC01.finbridge.local` resolves successfully from affected Floor 3 endpoints.
- Netlogon 5719 and DNS Client 1014 stop occurring during startup.
- Group Policy processes successfully without 1058, 1030, or 1129 errors.

## Lessons Learned
- DNS migrations must include dependent DHCP scope updates as part of the same controlled change, not as a follow-up task.
- Comparison against one unaffected machine can quickly distinguish infrastructure-wide failure from subnet-specific misconfiguration.
- Manual endpoint preconfiguration can temporarily mask infrastructure defects, so exception hosts should not be treated as proof of a clean rollout.