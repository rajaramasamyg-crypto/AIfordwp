# Microsoft 365 Copilot Readiness Checklist — Finance Department

**Date:** 2026-08-12  
**Department:** Finance (~200 users)  
**Prepared by:** IT / DWP Engineering  
**Status:** Pre-deployment

---

> **Priority note:** For this department, sections 3 (SharePoint/OneDrive Permissions) and 4 (Sensitivity Labelling) are the highest-priority gates. Copilot surfaces any content the signed-in user can read. With SharePoint permissions inherited and unaudited since a 2019 migration — across libraries containing payroll, board packs, M&A documents, and client financial data — oversharing via Copilot is the primary deployment risk. Do not assign licences until both sections are signed off.

---

## Section 1 — Licensing Prerequisites

- [ ] Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence in Entra ID / M365 Admin Center.
- [ ] Confirm no users are on legacy per-user plans (E3, F3) that would block Copilot add-on eligibility.
- [ ] Procure **Microsoft 365 Copilot add-on** licences (minimum: pilot cohort count; target: 200).
- [ ] Identify the Entra security group to be used for licence assignment (e.g., `LIC-Copilot-Finance-Pilot`).
- [ ] Assign Copilot add-on licences **only to the pilot group** via group-based licensing in Entra ID. Do not bulk-assign to all 200 users until Phase 1 go/no-go is passed.
- [ ] Confirm Microsoft 365 Copilot is not blocked by an admin-level feature disable or conditional access exclusion in the tenant.

---

## Section 2 — Microsoft 365 Apps Client Version

- [ ] Confirm Finance endpoints are running **Microsoft 365 Apps for Enterprise** (not Office 2019/2021 perpetual).
- [ ] Verify all Finance devices are on **Current Channel or Monthly Enterprise Channel** — Copilot features are not available on Semi-Annual Enterprise Channel until feature release lag clears.
- [ ] Confirm Microsoft 365 Apps build is **16.0.16327 or later** (minimum required for Copilot feature surface in Word, Excel, PowerPoint, Outlook, and Teams).
- [ ] Validate via Intune device compliance report or Microsoft 365 Apps health dashboard that no Finance devices are running an out-of-date build.
- [ ] Confirm **Click-to-Run** is the deployment method (MSI-based Office installations do not receive Copilot).
- [ ] Check that no Finance device has Microsoft 365 Apps update channel pinned or blocked by Intune policy at a version below the minimum.

---

## Section 3 — SharePoint and OneDrive Permissions — HIGHEST PRIORITY

> Finance SharePoint libraries contain payroll data, board packs, M&A documents, and client financial data. Permissions have been inherited from a 2019 migration and have not been audited since. This section must be completed and signed off before any Copilot licence is assigned to any Finance user.

### 3.1 — Permission Inheritance Audit

- [ ] Run a **SharePoint permission inheritance report** across all Finance-associated site collections, document libraries, and folder hierarchies. Export results to a spreadsheet for review.
- [ ] Identify all locations where **inheritance has been broken** and direct or one-off permissions have been granted — list each instance with the principal (user or group) and permission level.
- [ ] Identify all locations where **"Everyone", "Everyone except external users", or "All Company" groups** have been granted read access or higher to any Finance library. Remove or scope these immediately.
- [ ] Identify any **guest or external user** access to Finance SharePoint sites. Remove unless explicitly business-justified and approved by Finance leadership and IT Security.
- [ ] Document the **full permission baseline** (export) before remediation begins so that pre/post state can be compared and verified.

### 3.2 — High-Sensitivity Library Remediation

- [ ] For **payroll libraries and folders**: confirm access is restricted to named HR/Finance roles only. No group broader than the payroll team should have read access.
- [ ] For **board pack libraries**: confirm access is restricted to board members, company secretary, and designated administrators. Validate no Finance-wide or department-wide groups have inherited access.
- [ ] For **M&A document libraries**: confirm access is on a strict need-to-know basis. These libraries should be in a separate site collection if possible, with no inherited permissions from parent Finance sites.
- [ ] For **client financial data**: confirm access is scoped to the specific team responsible. Check for any inherited access from shared drives migrated in 2019 that may not reflect current team structures.

### 3.3 — OneDrive Oversharing Checks

- [ ] Review the **Microsoft 365 admin centre sharing report** or run a SharePoint Online Management Shell scan to identify Finance users who have shared OneDrive files externally.
- [ ] Check for OneDrive files shared with **"Anyone with the link"** within the Finance cohort — these are reachable by Copilot and represent uncontrolled disclosure risk.
- [ ] Confirm the tenant-level **OneDrive external sharing setting** is set to "Existing guests only" or "Only people in your organisation" for Finance-scoped sites. Coordinate with the M365 admin team if a site-level policy needs to be applied.

### 3.4 — Permission Audit Sign-off

- [ ] IT Security lead signs off that permission remediation is complete.
- [ ] Finance leadership (Finance Director or delegated data owner) confirms the access model reflects current business need.
- [ ] Written sign-off recorded and stored before any Copilot licence is activated.

---

## Section 4 — Sensitivity Labelling — HIGH PRIORITY

> Sensitivity labels are the primary control that limits what Copilot can summarise and share from labelled content. Without labels in place, Copilot treats all Finance content as equally accessible. E5 licensing includes Microsoft Purview Information Protection — this capability is already available at no additional cost.

- [ ] Confirm **Microsoft Purview Information Protection** is enabled in the tenant and sensitivity labels are published to Finance users.
- [ ] Define (or confirm existing) label taxonomy covering at minimum: `General`, `Confidential`, `Highly Confidential`, and `Highly Confidential — Restricted` (or equivalent organisation-specific labels).
- [ ] Apply labels to **payroll libraries**: minimum `Highly Confidential — Restricted`. Confirm label inheritance is enabled so all documents in the library inherit the label automatically.
- [ ] Apply labels to **board pack libraries**: minimum `Highly Confidential — Restricted`.
- [ ] Apply labels to **M&A document libraries**: minimum `Highly Confidential — Restricted`. Consider an additional scoped label (e.g., `M&A — Restricted`) if the organisation uses project-level labels.
- [ ] Apply labels to **client financial data libraries**: minimum `Highly Confidential`.
- [ ] Configure **DLP policies** in Purview to detect and block sharing of content labelled `Highly Confidential` or above via Teams chat, email, and Copilot prompt responses where applicable.
- [ ] Confirm **Copilot respects label-based access controls** — verify in a test tenant or pilot that a user without access to a labelled library cannot surface that content via a Copilot prompt.
- [ ] Enable **sensitivity label mandatory labelling** for new Finance documents in Word, Excel, and PowerPoint so that content created after go-live is labelled at creation time.

---

## Section 5 — Identity and MFA Readiness

- [ ] Confirm all ~200 Finance users are registered for **multi-factor authentication (MFA)** in Entra ID. Run the MFA registration report and remediate any gaps before the pilot.
- [ ] Confirm no Finance user accounts are excluded from **Conditional Access (CA) policies** that enforce MFA. Review CA exclusion group membership.
- [ ] Confirm Finance users are authenticating via **modern authentication** (OAuth 2.0 / MSAL). Legacy authentication must be blocked — verify the tenant-level legacy auth block is in place.
- [ ] Verify **Entra ID sign-in risk policies** are active for the Finance user population. High-risk sign-ins should trigger step-up authentication or block, not just alert.
- [ ] Check that all Finance user **UPNs and primary SMTP addresses are aligned** — mismatches can cause Copilot licence assignment and feature activation failures.
- [ ] Confirm Finance accounts are **not shared or generic accounts** (e.g., `finance.shared@company.com`). Copilot is a per-user licence and must be assigned to individual named accounts. Generic accounts should be excluded from the rollout.

---

## Section 6 — End-User Communications and Enablement

- [ ] Draft a **pre-launch communication** for Finance users covering: what Copilot is, what data it can access (and why the permission audit matters), what it cannot do, and the rollout timeline. Obtain sign-off from Finance leadership before sending.
- [ ] Prepare a **Finance-specific acceptable use guide** for Copilot, addressing: what types of prompts are appropriate, what to do if Copilot surfaces unexpected content, and prohibition on prompting Copilot with personally identifiable payroll data or M&A-restricted information in shared contexts (e.g., Teams meeting summaries with broader attendees).
- [ ] Confirm the **DWP Personal AI Usage Charter** has been reviewed against Finance-specific Copilot scenarios. If gaps exist, produce a Finance addendum and obtain sign-off from Legal/Policy before Phase 1.
- [ ] Schedule a **mandatory 30-minute Copilot orientation session** for all pilot users before their licence is activated. Include: how to write effective prompts, how to verify AI-generated outputs, and how to report concerns.
- [ ] Establish a **feedback and incident channel** (e.g., a dedicated Teams channel or ServiceNow queue) for Finance users to report unexpected behaviour, content surprises, or data concerns during the pilot.
- [ ] Confirm **line manager awareness** — Finance team leads should be briefed before the pilot goes live so they can handle questions and reinforce acceptable use guidance with their teams.
- [ ] Schedule a **pilot review meeting** at day 5 and day 10 of Phase 1 to review usage telemetry, feedback themes, and any DLP or Purview alerts triggered.

---

## Sign-off Summary

| Section | Responsible | Sign-off required before |
|---|---|---|
| 1 — Licensing | IT / M365 admin | Pilot licence assignment |
| 2 — Client version | IT / Endpoint team | Pilot licence assignment |
| 3 — SharePoint/OneDrive permissions | IT Security + Finance data owner | **Any** licence assignment |
| 4 — Sensitivity labelling | Security / Purview admin | **Any** licence assignment |
| 5 — Identity/MFA | IT Security / Identity team | Pilot licence assignment |
| 6 — Comms and enablement | IT + Finance leadership + Legal | Pilot go-live |
