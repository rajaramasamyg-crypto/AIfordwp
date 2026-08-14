# Incident Triage — Login Failures + Unauthorized Data Exposure
**Date:** 2026-08-14  
**Prepared by:** DWP Service Desk / Incident Triage  
**Status:** Triage in progress

---

## Overview
Two separate but concurrent incidents reported:
1. **Access failure** — ~22 users unable to log into VDI / launch Citrix sessions
2. **Security breach** — Paralegal received Copilot response showing confidential client matter she claims never had access to

These incidents are tangled in urgency and scope, requiring parallel triage but different remediation paths.

---

## Problem 1: VDI Login Failures (22 of 30 users in FinBridge-VDI-Pool-02)

### Severity & Scope
- **Severity:** HIGH  
- **Impact:** Finance users unable to access line-of-business applications via Citrix
- **Affected population:** 22 of 30 users in FinBridge-VDI-Pool-02 (unaffected control: FinBridge-VDI-Pool-01 with 19/20 registered)
- **Business continuity risk:** CRITICAL — Finance operations may stall without VDI access

### Symptom
- Session launch error: **Citrix Error 1030 — "No machines available in the desktop group"**
- Users unable to initiate remote session

### First Diagnostic Step & Why
**Priority 1 (Immediate, <15 min):**  
Check **Citrix Broker Service status on dc-vdi-02** and **VDA registration ratio for FinBridge-VDI-Pool-02**

**Why this first:**
- Error 1030 indicates no registered capacity in the broker's inventory. The broker cannot assign a session because it has no healthy machines to hand out.
- Broker Service stoppage or hung state is the #1 root cause of mass unregistration, because VDAs cannot communicate their health status to the controller.
- Cross-pool comparison (Pool-01 healthy at 19/20 registered vs Pool-02 degraded at 3/25 registered) immediately narrows root cause to the Pool-02 control plane or delivery controller.

**What to check:**
- On **dc-vdi-02 (Pool-02's controller)**: Open Services → Citrix Broker Service → Status (should be Running; if Stopped, that's the blocker).
- In **Citrix Director** → Farm → Desktop Groups → FinBridge-VDI-Pool-02 → Machines: Count registered vs provisioned. If <50% registered, controller health is the problem.
- Compare to Pool-01 status to confirm isolation to Pool-02.

---

**Priority 2 (5-10 min follow-up if Service is running):**  
Check **Windows Update status and pending reboot state on dc-vdi-02**

**Why this second:**
- If Broker Service stopped after patching but admin did not complete reboot, the service may restart but the kernel-level changes won't apply, leaving the system in a compromised state.
- Pending reboot + Service stopped is a known pattern in post-patch scenarios.

**What to check:**
- On **dc-vdi-02**: Run PowerShell: `Get-HotFix | Where-Object { $_.InstalledOn -gt (Get-Date).AddDays(-1) }` to see if patches installed in the last 24h.
- Check if reboot is required: `systeminfo | findstr "System Boot Time"` and compare to patch install time in event logs.
- Check Citrix event log (`Event Viewer → Applications and Services Logs → Citrix`) for entries around the time of the patch and Broker Service state changes.

---

**Priority 3 (Escalation if Priorities 1 & 2 don't resolve):**  
If Broker Service is running AND reboot is complete, check **network connectivity between VDAs and dc-vdi-02**, and **Citrix licensing service availability**

**Why this third:**
- If the controller is healthy but VDAs cannot communicate with it, registration will still fail. This is less common but requires network/firewall validation.
- Licensing service outage can also prevent registration.

---

## Problem 2: Unauthorized Data Exposure via Copilot (Confidential Client Matter)

### Severity & Scope
- **Severity:** CRITICAL / SECURITY INCIDENT  
- **Impact:** Paralegal received Copilot-surfaced content (settlement draft) from a confidential matter she claims she has no authorization to access
- **Affected population:** 1 paralegal (to confirm); possibly others with inherited/unaudited permissions  
- **Regulatory risk:** GDPR, FCA, contractual obligation breach — confidential client financial data may have been surfaced outside permitted scope
- **Board-level risk:** YES — material control failure if M&A or sensitive client documents are accessible via unintended permission inheritance

### Symptom
- User prompted Copilot to retrieve / summarise content from a client settlement matter
- Copilot returned or surfaced a draft settlement document
- User claims she has never been assigned to that matter and should not have access

### First Diagnostic Step & Why
**Priority 1 (IMMEDIATE, <5 min — escalate in parallel):**  
**Confirm the paralegal CAN directly open the document in SharePoint without Copilot**

**Why this first:**
- Copilot can ONLY surface content the signed-in user has read permission to access. If Copilot surfaced the document, the user's account already has underlying SharePoint/Drive read access.
- This is not a Copilot defect; it is a **permissions misconfiguration**.
- If the user can open the file directly in SharePoint but cannot explain how she got access, that indicates inherited or over-permissive group membership — the highest-risk scenario in the pre-deployment audit.

**What to check:**
1. **Ask the paralegal:** "Can you open this file directly in SharePoint with your account, using the same browser and device?" (Do not ask her to open it; just confirm she can.)
2. If YES → Go to Priority 2 immediately (permissions audit).
3. If NO → This is a different issue (Copilot indexing stale data, or she has delegated access path she's unaware of). Still escalate but sequence differently.

---

**Priority 2 (IMMEDIATE, <10 min — parallel to Priority 1 confirmation):**  
**Check SharePoint folder permissions for the settlement matter, specifically:**
- Membership of security groups with read/edit access to the matter folder
- Whether the paralegal's account or her team's security group is a member of an over-permissive group (e.g., "All Company", "All Staff", "All Finance", "All Legal")
- Whether the folder has inherited permissions from a parent library that contains multiple matters/clients

**Why this second:**
- The 2019 SharePoint migration left unaudited permission inheritance in place. This is the #1 risk vector for Copilot surfacing unintended content.
- If the paralegal's user account or her team group is nested inside an over-permissive parent group, she has inherited read access without explicit assignment to that matter.
- This indicates the blocker from the pre-deployment readiness plan was not resolved: **SharePoint permissions were not remediated before Copilot licence assignment**.

**What to check:**
1. In **SharePoint** → Matter folder (e.g., "Client-XYZ-Settlement-2026") → Settings → Permissions → Check group membership of all groups with access.
2. Look for the paralegal's user account or her team/department group listed directly or via nesting.
3. Trace up the group hierarchy: If her account is in "Legal Team" and "Legal Team" is in "All Staff" and "All Staff" has read access to Finance/Legal libraries, that's the inheritance chain.
4. For each group found, note:
   - Is the group membership intentional / documented?
   - Was this group added before or after the 2019 migration?
   - Does the group give access to multiple matters, or only this one?
5. **If the folder has inherited permissions (rather than unique permissions):** Check the parent library's permissions and repeat the analysis up the tree.

---

**Priority 3 (10-30 min follow-up):**  
**If underlying permissions are confirmed, determine if access is intentional or a legacy artifact**

**Why this third:**
- Not all permission findings are breaches. The paralegal may have legitimate delegated access for a reason she doesn't recall (e.g., she was added to a matter team 6 months ago and cycled off the active workstream but remains in the group).
- Distinguishing intentional from unintended access determines whether the fix is removal vs. documentation vs. reassignment.

**What to check:**
1. **Ask Finance/Legal management:** Is this paralegal supposed to have access to this matter? Has she been assigned to it at any point in the past 12 months?
2. **Check Active Directory group membership history** (if available via identity audit logs) for when the paralegal's account was added to the group and any removal date.
3. **Interview the matter custodian** (the attorney or partner assigned to this client) to confirm whether the paralegal should be on the access list.

---

**Priority 4 (Escalation & containment, 30-60 min, parallel to Priority 2 if possible):**  
**If the paralegal should NOT have access:**  
1. **Immediately remove her account from the security group or the folder permissions** (coordinated with Legal/Finance leadership).
2. **Notify Finance/Legal leadership and Compliance** of the potential data exposure incident.
3. **Initiate a wider permissions audit** across all Finance/Legal SharePoint libraries to identify other potentially over-permissive groups (this was a pre-deployment requirement that may not have been completed).
4. **Document the incident for regulatory reporting** — depending on the sensitivity of the exposed content and the client contract, this may trigger GDPR/FCA reporting obligations.

---

## Root Cause Summary (Preliminary)

### Problem 1: VDI Login Failures
- **Primary cause (likely):** Citrix Broker Service stopped after Windows Update on dc-vdi-02, with reboot not completed. Mass VDA unregistration followed, reducing available session capacity below demand.
- **Contributing factor:** No enforced post-maintenance checkpoint to verify Broker Service restart and registration health before handover to production.

### Problem 2: Unauthorized Data Exposure
- **Primary cause:** SharePoint permissions inherited from unaudited 2019 migration; over-permissive security group nesting allowed the paralegal's account (directly or via group membership) to retain read access to a client matter she should not be assigned to.
- **Contributing factor:** Pre-deployment Copilot readiness plan required SharePoint permission audit completion before licence assignment; this may not have been signed off or completed before rollout.
- **Secondary contributing factor:** Copilot's grounding correctly respects the underlying SharePoint permissions; the issue is not with Copilot, but with permissions misconfiguration in the data store.

---

## Triage Action Summary (Sequence)

| Priority | Problem | Action | Owner | Target Time |
|---|---|---|---|---|
| **1 (IMMEDIATE)** | Problem 2 (Security) | Confirm paralegal can directly open document in SharePoint; escalate to Leadership + Compliance if YES | Service Desk → Legal/Compliance | <5 min |
| **1 (IMMEDIATE)** | Problem 1 (Access) | Check dc-vdi-02 Broker Service status and Pool-02 VDA registration ratio | VDI Admin / EUC Team | <15 min |
| **2 (URGENT)** | Problem 2 (Security) | Pull SharePoint folder permissions and trace group membership; identify over-permissive inheritance | SharePoint Admin + Legal/Finance | <30 min |
| **2 (URGENT)** | Problem 1 (Access) | If Service stopped, reboot dc-vdi-02 and verify Broker Service restart + registration recovery | VDI Admin / EUC Team | <30 min |
| **3 (HIGH)** | Problem 2 (Security) | Confirm with Legal/Finance leadership whether paralegal should have access; if NO, remove permissions | Leadership decision → SharePoint Admin | <60 min |
| **3 (HIGH)** | Problem 2 (Security) | Initiate broader Finance/Legal SharePoint permissions audit per pre-deployment plan | IT Security + SharePoint Admin | 1-7 days |
| **4 (ONGOING)** | Problem 1 (Access) | Monitor Pool-02 registration and launch success; collect evidence for post-incident review | VDI Admin / EUC Team | Continuous until resolution sign-off |

---

## Escalation Path

- **VDI Login Failures (Problem 1):** Escalate to EUC/VDI Platform Team Lead → IT Operations Director if not resolved within 1 hour.
- **Security Data Exposure (Problem 2):** Escalate to IT Security Lead + Legal/Compliance Officer **immediately** (do not wait for other confirmations). This is a regulatory incident.

---

## Known Risks & Open Questions

### Problem 1
- **Unknown:** Whether other VDI pools are also affected (need to check all pool registrations across the environment).
- **Unknown:** Whether VDAs were rebooted automatically or require manual intervention post-reboot of dc-vdi-02.

### Problem 2
- **Unknown:** How many other users may have similar over-permissive access to sensitive matters (requires full audit).
- **Unknown:** Whether the client who owns the settlement draft has been notified or whether this rises to a contractual breach / SLA violation requiring client notification.
- **Unknown:** Whether similar issues exist in other applications (SharePoint, Teams, OneDrive) beyond Copilot.

---

## Reference Documents
- [Citrix Session Launch Failure RCA — FinBridge-VDI-Pool-02 (2026-08-14)](../../../Day9/RCA-citrix-session-launch-failure-finbridge-pool-02-2026-08-14.md)
- [Copilot Deployment Context — Finance Department (2026-08-12)](../../../Day8/copilot-deployment-context-finance-2026-08-12.md) — Pre-deployment audit requirements
- [End-User Communication — Settlement Draft Unexpected Access (2026-08-12)](../../../Day5/end-user-comm-settlement-draft-unexpected-access.md)
