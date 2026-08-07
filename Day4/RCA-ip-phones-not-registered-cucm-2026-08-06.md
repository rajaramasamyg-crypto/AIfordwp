# Root Cause Analysis (RCA): IP Phones Not Registered in Cisco CUCM

## Incident Summary
- Incident type: Enterprise IP telephony registration failure
- Affected platform: Cisco Unified Communications Manager (CUCM)
- Affected endpoint type: Cisco IP phones (multiple models)
- Impact: Users could not place or receive calls from affected desk phones
- Detection time: 2026-08-06 08:20
- Containment time: 2026-08-06 09:05
- Full service restoration: 2026-08-06 09:40

## Executive Summary
A large number of Cisco IP phones failed to register to the CUCM cluster, causing a broad desk-phone outage for impacted users. Investigation showed the phones were reachable on the network, but registration attempts were rejected due to an expired or invalid ITL/CTL trust state after recent CUCM certificate changes. This created a mismatch between phone trust data and CUCM security state, preventing normal SIP/SCCP registration.

The issue was resolved by correcting CUCM trust and certificate alignment, resetting trust on affected phones, and forcing endpoint re-registration. Service was validated after successful registration recovery and stable call tests.

## Supporting Evidence

### Observed Symptoms
- Phone displays showed "Registering" then "Registration Rejected" or remained unregistered.
- Users reported no dial tone and inability to receive inbound calls.
- CUCM device status showed many endpoints in Unregistered state.

### CUCM and Endpoint Indicators
- CUCM traces showed repeated registration attempts from affected device MAC addresses.
- Security/trust-related errors were present during device authentication and registration.
- Network checks confirmed phone VLAN, DHCP, and TFTP reachability were healthy.
- Impact was cluster-wide for devices that had not refreshed trust after certificate updates.

## Timeline
1. 08:20 - Service desk received first reports of desk phones failing to register.
2. 08:30 - Monitoring confirmed a sharp increase in Unregistered phones in CUCM.
3. 08:40 - Network team validated voice VLAN, DHCP scope health, and CUCM node connectivity.
4. 08:50 - UC team identified trust/certificate mismatch indicators in CUCM logs.
5. 09:05 - Containment started: trust remediation steps initiated for affected phones.
6. 09:20 - Phased phone resets and re-registration workflow executed.
7. 09:40 - Registration levels returned to baseline; test calls confirmed restored service.

## Root Cause Statement
The primary root cause was a CUCM trust and certificate mismatch following certificate-related changes, which caused affected IP phones to reject CUCM security identity and fail registration until trust was reset and re-established.

## Five Whys Analysis

### Problem
Why were IP phones not registered in CUCM?
- Because endpoint registration attempts were failing at the trust/security validation phase.

### Why 1
Why did trust/security validation fail?
- Because phone ITL/CTL trust data was no longer aligned with current CUCM certificate state.

### Why 2
Why was trust data not aligned?
- Because certificate changes were introduced without ensuring all phones refreshed trust successfully.

### Why 3
Why did phones not refresh trust automatically?
- Because a subset of endpoints retained stale trust state and could not complete secure update flow.

### Why 4
Why did stale trust remain undetected before impact?
- Because post-change validation focused on a limited sample and did not include broad registration health checks.

### Why 5
Why were broad registration checks not mandatory?
- Because the operational change process lacked a formal CUCM trust/certificate validation checklist across all phone segments.

## Corrective Actions Taken
1. Reviewed CUCM certificate and security configuration consistency across cluster nodes.
2. Performed trust reset/remediation on impacted phones.
3. Restarted TFTP-related phone configuration retrieval where needed.
4. Triggered endpoint reset and forced re-registration in controlled batches.
5. Verified restored endpoint registration and completed inbound/outbound call tests.

## Preventive Actions
1. Implement a formal pre/post-change checklist for CUCM certificate and trust operations.
2. Add automated alerting for abnormal spikes in Unregistered device counts.
3. Include representative device models and sites in post-maintenance validation.
4. Document and rehearse ITL/CTL recovery runbook for service desk and UC engineers.
5. Schedule periodic certificate expiry and trust health audits for CUCM clusters.

## Verification of Resolution
- CUCM Unregistered phone count returned to normal baseline.
- Sample validation across sites confirmed successful phone registration.
- Functional call tests (internal and external) succeeded.
- No recurring registration spike observed during post-incident monitoring window.

## Lessons Learned
- CUCM certificate/trust changes can trigger broad registration impact if endpoint trust refresh is incomplete.
- Registration health should be monitored as a first-class KPI during UC maintenance windows.
- Early cross-team triage (UC plus network plus service desk) accelerates isolation and restoration.