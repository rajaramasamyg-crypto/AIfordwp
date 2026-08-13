# Root Cause Analysis (RCA): Microsoft Intune Service Intermittent Access Issues – APAC Region

**Document type:** Customer-facing RCA  
**Incident date:** 2026-08-10  
**RCA published:** 2026-08-12  
**Status:** Resolved

---

## Executive Summary

On 10 August 2026, users across the APAC region experienced intermittent failures when accessing Microsoft Intune services, including the Intune portal, device enrolment, policy sync, and Company Portal. The disruption was caused by elevated latency and partial unavailability on a subset of backend service nodes serving the APAC region, triggered by an infrastructure scaling operation that did not complete as expected. Service was progressively restored throughout the day and fully confirmed resolved by end of business 2026-08-10. No data loss occurred.

---

## Incident Summary

| Field | Detail |
|---|---|
| **Affected service** | Microsoft Intune (device management, policy sync, enrolment, Company Portal) |
| **Affected region** | APAC |
| **Incident start** | 2026-08-10 07:15 AEST (2026-08-09 21:15 UTC) |
| **Incident end** | 2026-08-10 16:40 AEST (2026-08-10 06:40 UTC) |
| **Total duration** | Approximately 9 hours 25 minutes |
| **Impact type** | Intermittent – not all requests failed; behaviour was inconsistent across users and devices |
| **Data loss** | None |
| **Resolution status** | Fully resolved |

---

## Customer Impact

During the incident window, affected users and administrators may have experienced one or more of the following:

- Inability to sign in to the Intune admin portal at endpoint.microsoft.com
- Company Portal displaying errors or failing to load assigned applications
- Device policy sync failures or delayed compliance status updates
- Device enrolment failures or timeouts
- Conditional Access policies intermittently blocking access due to stale compliance state

Users and devices outside the APAC region were not affected.

---

## Timeline

| Time (AEST) | Time (UTC) | Event |
|---|---|---|
| 06:30 | 20:30 (09 Aug) | Scheduled infrastructure scaling operation begins on APAC backend node cluster |
| 07:15 | 21:15 (09 Aug) | First user-facing errors detected; Intune service health monitoring triggers alert |
| 07:28 | 21:28 (09 Aug) | Incident declared; engineering team engaged |
| 08:10 | 22:10 (09 Aug) | Root cause identified as incomplete node promotion during scaling operation |
| 08:45 | 22:45 (09 Aug) | Mitigation begun: traffic rerouted away from degraded nodes |
| 10:20 | 00:20 (10 Aug) | Partial restoration confirmed; approximately 60% of requests processing normally |
| 13:05 | 03:05 (10 Aug) | Degraded nodes remediated and returned to service; traffic rebalanced |
| 16:40 | 06:40 (10 Aug) | Full service restoration confirmed across all APAC endpoints |
| 17:00 | 07:00 (10 Aug) | Incident closed; monitoring extended for 24 hours |

---

## Root Cause Statement

A scheduled infrastructure scaling operation in the APAC region introduced a subset of backend service nodes that did not complete their promotion sequence correctly. These nodes entered a partially active state — accepting incoming traffic routing but unable to process requests reliably — causing intermittent failures for a proportion of APAC user sessions. The automated health checks that should have detected and excluded these nodes from the traffic pool did not trigger within the expected threshold window, allowing degraded nodes to serve live traffic for an extended period before manual intervention rerouted affected sessions.

---

## Five Whys Analysis

**Why did users experience intermittent Intune access failures?**  
Because a subset of APAC backend nodes were serving requests in a degraded state, causing a proportion of those requests to fail.

**Why were nodes in a degraded state?**  
Because a scaling operation added new nodes that did not complete their promotion sequence, leaving them partially initialised.

**Why did degraded nodes receive live traffic?**  
Because automated health checks did not exclude them within the expected threshold — the checks passed an initial ping test but did not validate full request-processing capability before traffic was assigned.

**Why did health checks not catch the partial failure?**  
Because the health check configuration tested connectivity only and not end-to-end request completion, meaning nodes that could respond to pings but not process authenticated service calls were not flagged as unhealthy.

**Why was this not detected sooner?**  
Because the monitoring alert threshold was set to trigger on sustained failure rates above 30% across the cluster; the intermittent nature of the degradation (affecting a proportion rather than all requests) kept the aggregate failure rate below that threshold until user reports and secondary monitoring surfaced the issue.

---

## Preventive Actions

| Action | Owner | Target date |
|---|---|---|
| Update health check configuration to validate end-to-end request processing, not connectivity only, before nodes receive live traffic | Infrastructure Engineering | 2026-08-28 |
| Lower monitoring alert threshold for APAC clusters to detect intermittent degradation below the 30% sustained failure level | Site Reliability Engineering | 2026-08-21 |
| Add an automated rollback gate to scaling operations: nodes that do not complete full promotion within a defined window are automatically excluded from traffic routing | Infrastructure Engineering | 2026-09-05 |
| Review scaling operation runbooks to include explicit validation steps before traffic is assigned to newly promoted nodes | Change Management | 2026-08-21 |

---

## What Customers Should Do

No action is required from customers. All Intune services are fully restored. If you continue to experience any issues related to Intune access, device compliance, or policy sync, please contact your Microsoft support representative or raise a support request via the Microsoft 365 admin centre.

If devices are still showing a non-compliant status after 2026-08-10 16:40 AEST, triggering a manual sync from Company Portal or the Intune admin portal will update the compliance state.

---

## Apology

We sincerely apologise for the disruption this incident caused to your organisation. We understand the impact of Intune availability on device management, application deployment, and Conditional Access, and we are committed to the preventive actions above to reduce the likelihood of recurrence.

---

*This document is provided for informational purposes. If you have questions regarding this incident, please contact your Microsoft account team or support representative.*
