# Microsoft 365 Copilot Readiness — Tiered Priority Ranking: Finance Department

**Date:** 2026-08-12  
**Source checklist:** copilot-readiness-checklist-finance-2026-08-12.md  
**Department:** Finance (~200 users)  
**Prepared by:** IT / DWP Engineering

---

## Why the permissions audit ranks higher than licensing — Finance-specific justification

Licensing and client version checks are simpler to verify and faster to remediate. A missing licence means Copilot does not activate — the blast radius of getting it wrong is zero; no one gets access they should not have. A failed client version check is equally contained: the feature surface does not appear.

The permissions and oversharing audit is categorically different in failure mode.

If Copilot licences are assigned before the SharePoint permission estate is cleaned up, Copilot immediately begins traversing a permission model that has not been validated since 2019. Every Finance user who receives a licence can prompt Copilot and receive synthesised answers drawn from any document they have read access to — including content they have inherited access to through stale group memberships, broken inheritance chains, or overly broad migration-era grants. This is not a theoretical risk. It is the default behaviour of Copilot; it is working as designed.

For a Finance department holding payroll data, board packs, M&A documents, and client financial data, the consequences of that default behaviour against an unaudited permission model are:

- **Regulatory exposure** — payroll data or client financial data surfaced to users outside the intended access group is a potential GDPR and FCA breach, regardless of whether it was intentional.
- **Legal exposure** — M&A documents accessible to users who were never cleared for that workstream may constitute a material control failure with board-level consequences.
- **No visible trigger** — unlike a traditional file access, a Copilot response synthesising restricted content does not generate a DLP alert unless labels and policies are already in place. The disclosure happens silently.
- **Irreversibility** — once content is surfaced in a Copilot response and potentially copied, forwarded, or acted upon, the disclosure cannot be undone by a retrospective permission fix.

Licensing can be assigned in minutes once the permission estate is clean. The permission audit cannot be completed in minutes once licences are live. The sequencing is therefore non-negotiable: permissions first, licences second.

---

## Tier 1 — MUST complete before rollout (Blocking)

These items must be signed off before any Copilot licence is assigned to any Finance user, including pilot participants. If any item in this tier is incomplete, the rollout does not proceed.

### Permissions and Oversharing (Section 3 of checklist) — Highest priority in this tier

- [ ] Run SharePoint permission inheritance report across all Finance site collections, libraries, and folders. Export and review results.
- [ ] Identify and remove all instances of "Everyone", "Everyone except external users", or "All Company" groups with read access or higher to any Finance library.
- [ ] Identify and remove all guest or external user access to Finance SharePoint sites unless explicitly re-approved.
- [ ] Remediate payroll libraries: restrict access to named HR/Finance roles only.
- [ ] Remediate board pack libraries: restrict to board members and designated administrators only.
- [ ] Remediate M&A document libraries: strict need-to-know, isolated from parent Finance site inheritance where possible.
- [ ] Remediate client financial data libraries: scoped to responsible team only.
- [ ] Review OneDrive sharing for Finance users — remove "Anyone with the link" shares.
- [ ] Document pre- and post-remediation permission baseline.
- [ ] Obtain written sign-off from IT Security lead and Finance data owner (Finance Director or delegated).

**Why blocking:** See justification above. This is the only item in the checklist where an incorrect state at go-live produces a silent, potentially irreversible data disclosure. Every other MUST item either prevents Copilot from working at all (licensing, client version) or prevents account compromise (MFA). Only the permissions audit prevents Copilot from working *incorrectly*.

### Sensitivity Labelling (Section 4 of checklist)

- [ ] Confirm Microsoft Purview Information Protection is enabled and labels are published to Finance users.
- [ ] Apply `Highly Confidential — Restricted` (or equivalent) to payroll, board pack, and M&A libraries with label inheritance enabled.
- [ ] Apply `Highly Confidential` or above to client financial data libraries.
- [ ] Configure DLP policies to detect and block sharing of `Highly Confidential` content via Teams, email, and Copilot prompt responses.
- [ ] Verify in a controlled test that a user without access to a labelled library cannot surface that content via Copilot.

**Why blocking:** Labels are the secondary control layer sitting on top of permissions. If the permission audit misses anything — stale inheritance, an overlooked group — sensitivity labels and DLP policies are the last line of defence preventing that content from being surfaced by Copilot. Deploying without labels means there is no backstop.

### Identity and MFA (Section 5 of checklist)

- [ ] Confirm all ~200 Finance users are registered for MFA. Remediate any gaps.
- [ ] Confirm no Finance user is excluded from Conditional Access policies enforcing MFA.
- [ ] Confirm legacy authentication is blocked for Finance accounts.
- [ ] Confirm Finance accounts are individual named accounts — no generic or shared accounts in scope for Copilot licensing.

**Why blocking:** Copilot operates in the context of the signed-in user's identity. An account that can be compromised via legacy authentication or a missing MFA registration becomes a vector for an attacker to query Copilot across the entire Finance permission estate. For a department holding this data, an unprotected account is an unprotected Copilot session.

### Licensing — Pilot Group Only (Section 1 of checklist)

- [ ] Confirm all Finance users hold active M365 E5 licences.
- [ ] Create pilot security group (`LIC-Copilot-Finance-Pilot`) with 10–15 users who do not have routine access to payroll or M&A workstreams.
- [ ] Assign Copilot add-on licences to pilot group only via group-based licensing. Do not assign to all 200 users.
- [ ] Confirm Copilot is not blocked by tenant-level feature disable or CA exclusion.

**Why blocking:** Without the licence assigned to at least the pilot group, the pilot cannot run. Scoped to pilot group only — broad assignment is a Tier 2 item, conditional on pilot sign-off.

---

## Tier 2 — SHOULD complete before rollout (High risk if skipped)

These items do not technically prevent Copilot from activating but represent meaningful risk to the department or the broader user population if deferred. Aim to complete all of these before Phase 1 pilot go-live.

### Microsoft 365 Apps Client Version (Section 2 of checklist)

- [ ] Confirm Finance endpoints are running Microsoft 365 Apps for Enterprise (not perpetual Office).
- [ ] Confirm Current Channel or Monthly Enterprise Channel — not Semi-Annual Enterprise Channel.
- [ ] Confirm build is 16.0.16327 or later across all Finance devices.
- [ ] Verify no Finance device has update channel pinned below the minimum via Intune policy.
- [ ] Confirm Click-to-Run deployment (not MSI).

**Why Tier 2 and not Tier 1:** An out-of-date build means Copilot features do not surface for that user — the failure is self-contained and produces no data risk. However, a mixed-build environment during a pilot creates inconsistent user experience and makes feedback difficult to interpret. Validate this before the pilot, but it is not a data risk in the way permissions are.

### End-User Communications (Section 6 of checklist — pre-launch items)

- [ ] Draft and send pre-launch communication to pilot users covering what Copilot accesses and the rollout timeline.
- [ ] Produce Finance-specific acceptable use guide covering prompt boundaries, unexpected content handling, and prohibition on prompting with PII payroll data or M&A content in shared contexts.
- [ ] Review DWP Personal AI Usage Charter for Finance-specific Copilot gaps. Produce addendum if required and obtain Legal/Policy sign-off.
- [ ] Brief Finance line managers before pilot goes live.

**Why Tier 2:** Users who receive a Copilot licence without guidance will experiment freely — including prompting in ways that create policy or regulatory risk. Acceptable use guidance is not bureaucratic overhead; for a Finance department it is an active risk control. It should be in place before the first pilot licence is active.

### Entra ID Sign-in Risk Policies (Section 5 of checklist)

- [ ] Verify Entra ID sign-in risk and user risk policies are active and scoped to Finance users.
- [ ] Confirm high-risk sign-ins trigger step-up authentication or block — not just an alert.

**Why Tier 2:** This is an identity hygiene item that should already be in place for a Finance department regardless of Copilot. Copilot raises the stakes because a compromised session now carries Copilot query capability across the Finance estate.

---

## Tier 3 — CAN complete during or after rollout (Lower risk, does not block)

These items improve the long-term health and governance of the deployment but do not represent acute risk at go-live, assuming Tier 1 and Tier 2 items are complete.

### Licensing — Broad Assignment (Section 1 of checklist)

- [ ] Assign Copilot add-on licences to remaining ~185 Finance users after Phase 1 go/no-go sign-off.
- [ ] Confirm UPN and primary SMTP alignment for all Finance users ahead of broad assignment.

**Why Tier 3:** Broad licence assignment is deliberately deferred until the pilot validates that Copilot is behaving correctly across the permission and label estate. This is sequencing by design, not an oversight.

### Mandatory Sensitivity Labelling for New Documents (Section 4 of checklist)

- [ ] Enable mandatory labelling for new Finance documents created in Word, Excel, and PowerPoint.

**Why Tier 3:** This governs content created *after* go-live. The Tier 1 label work covers the existing estate, which is where the historical risk sits. Mandatory labelling for new content is good governance and should be configured during Phase 1, but it does not affect existing documents that Copilot will traverse on day one.

### Pilot Feedback and Monitoring Infrastructure (Section 6 of checklist)

- [ ] Establish dedicated Teams channel or ServiceNow queue for Copilot feedback and data concern reports.
- [ ] Schedule pilot review meetings at day 5 and day 10 of Phase 1.
- [ ] Configure Microsoft 365 Copilot usage reports in the M365 Admin Center for prompt activity monitoring.

**Why Tier 3:** These are operational controls for the pilot period. They should be in place by day 1 of Phase 1 but do not need to be ready before the pilot is approved to start.

### Mandatory Orientation Session for Broad Rollout Users (Section 6 of checklist)

- [ ] Schedule and deliver 30-minute Copilot orientation for all remaining ~185 Finance users before their licences are activated in Phase 2.

**Why Tier 3:** Applies to Phase 2 users only. Pilot users receive orientation as a Tier 2 item. Broad rollout orientation is planned during the pilot window and delivered before Phase 2 activation.

---

## Summary Table

| Checklist area | Tier | Gate |
|---|---|---|
| SharePoint/OneDrive permission audit and remediation | **MUST** | Before any licence assigned |
| Sensitivity labels applied to high-sensitivity libraries | **MUST** | Before any licence assigned |
| DLP policies covering Copilot and labelled content | **MUST** | Before any licence assigned |
| MFA registration — all 200 Finance users | **MUST** | Before any licence assigned |
| Conditional Access — no Finance user excluded | **MUST** | Before any licence assigned |
| Legacy authentication blocked | **MUST** | Before any licence assigned |
| No generic/shared accounts in pilot scope | **MUST** | Before pilot licence assigned |
| Copilot pilot licence assignment — pilot group only | **MUST** | Before pilot go-live |
| M365 Apps client version and channel validation | **SHOULD** | Before pilot go-live |
| Pre-launch comms and acceptable use guide | **SHOULD** | Before pilot go-live |
| DWP AI Usage Charter — Finance addendum | **SHOULD** | Before pilot go-live |
| Finance line manager briefing | **SHOULD** | Before pilot go-live |
| Sign-in risk policies active for Finance users | **SHOULD** | Before pilot go-live |
| Broad Copilot licence assignment — remaining 185 users | **CAN** | After Phase 1 sign-off |
| Mandatory labelling for new Finance documents | **CAN** | During Phase 1 |
| Pilot feedback channel and monitoring setup | **CAN** | By day 1 of Phase 1 |
| Orientation session for Phase 2 users | **CAN** | During Phase 1, before Phase 2 |
