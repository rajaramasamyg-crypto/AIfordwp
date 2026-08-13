# Microsoft 365 Copilot — Deployment Context: Finance Department

**Date:** 2026-08-12  
**Status:** Pre-deployment planning  
**Owner:** IT / Change & Release  
**Audience:** Project team, IT Security, Data Governance, Finance leadership

---

## 1. Deployment Overview

| Item | Detail |
|---|---|
| Target department | Finance |
| User count | ~200 |
| M365 licensing | E5 — confirmed, all 200 seats |
| Copilot add-on | Not yet assigned |
| Data sensitivity classification | High |
| Planned rollout model | Phased (pilot → broad) |

---

## 2. Data Sensitivity Profile

Finance is a high-risk department for AI-assisted tooling due to the nature of data in scope.

| Data type | Location | Risk if over-shared |
|---|---|---|
| Payroll data | SharePoint / shared drives | Legal, regulatory, employment law exposure |
| Board packs | SharePoint document libraries | Confidential — restricted to board/exec only |
| M&A documents | SharePoint / shared drives | Highly sensitive — potential market/legal impact |
| Client financial data | Shared drives | Contractual and regulatory obligations (FCA, GDPR) |

**Key risk:** Copilot surfaces content the signed-in user has read access to. If SharePoint permissions are over-permissive due to the unaudited 2019 migration inheritance state, Copilot responses may expose content users should not have access to — without generating a traditional access log entry that would trigger a security alert.

---

## 3. Identified Blockers and Pre-conditions

### 3.1 BLOCKER — SharePoint Permission Audit (Critical, must resolve before license assignment)

SharePoint permissions are currently inherited from a 2019 migration and have not been audited since. This is the single highest-risk item in this deployment.

Actions required before any Copilot license is assigned:

- **Run a SharePoint permission inheritance report** across all Finance-related sites, libraries, and folders to identify broken inheritance chains, orphaned permissions, and direct-access grants that bypass group membership.
- **Identify overly broad groups** — e.g., "All Company" or "All Staff" groups with read access to Finance libraries containing sensitive content.
- **Remove or scope down direct user access** where a shared drive or library contains payroll, board pack, or M&A content and is accessible beyond the intended audience.
- **Validate sensitivity labels** are applied to high-sensitivity libraries (Payroll, Board Packs, M&A). If Microsoft Purview Information Protection is available under E5, this should be enforced before rollout.
- **Document baseline state** — export current permission snapshot so post-audit remediation can be verified.

> Target state before license assignment: Every Finance SharePoint library and shared drive must have permissions that reflect actual business need, with no inherited over-permissive access from the 2019 migration.

### 3.2 Licensing Assignment (Pending permission audit completion)

- Copilot for Microsoft 365 add-on licences are not yet assigned.
- Assignment should be blocked on sign-off from the permission audit. Do not assign licences to pilot users until audit remediation is confirmed complete for the Finance SharePoint estate.
- Assignment method: Intune / Entra group-based licensing, aligned to the pilot security group.

### 3.3 Acceptable Use and Data Governance Policy

- Confirm that the DWP Personal AI Usage Charter covers Copilot-specific scenarios, including: prompting Copilot with sensitive financial data, use of Copilot in Teams meetings where financial content is discussed, and Copilot-generated summaries of restricted documents.
- If the charter does not yet address these scenarios, a Finance-specific addendum should be drafted and approved before the pilot goes live.

---

## 4. Phased Rollout Plan

### Phase 0 — Pre-conditions (complete before any licence assignment)

| Task | Owner | Target |
|---|---|---|
| SharePoint permission inheritance report — Finance sites | IT Security / SharePoint admin | T+0 |
| Remediate over-permissive access — payroll, board packs, M&A libraries | SharePoint admin + Finance data owners | T+5 days |
| Apply / validate sensitivity labels on high-sensitivity libraries | Security / Purview admin | T+5 days |
| Confirm AI usage charter covers Finance Copilot scenarios | Policy / Legal | T+5 days |
| Document and sign off permission baseline | IT Security + Finance leadership | T+7 days |

### Phase 1 — Pilot (~10–15 users)

- **Scope:** Volunteer Finance users who do not have day-to-day access to the most sensitive content (payroll processing, M&A workstreams). Recommend selecting Finance Business Partners or FP&A analysts as initial cohort.
- **Duration:** 10 business days.
- **Monitoring:** Review Microsoft 365 Copilot usage reports in the M365 Admin Center for prompt activity. Review any Purview DLP or sensitivity label alerts triggered during pilot.
- **Feedback gate:** Collect structured feedback on workflow impact, unexpected content surfaced, and any concerns before proceeding to broad rollout.
- **Go/no-go criteria:** No data exposure incidents; no DLP policy breaches; user feedback confirms Copilot is surfacing contextually appropriate content only.

### Phase 2 — Broad Finance Rollout (~185 remaining users)

- **Trigger:** Successful Phase 1 go/no-go sign-off.
- **Wave structure:** Roll out in two waves (50% / 50%) with a 3-day monitoring gap between waves.
- **Exclusions:** Users with exclusive access to payroll processing systems or M&A restricted sites should be treated as a separate cohort with additional review before licence assignment.
- **Training:** Mandatory completion of a Finance-specific Copilot prompt guidance session before licence is activated for each user.

---

## 5. Security and Compliance Controls

| Control | Status | Notes |
|---|---|---|
| Microsoft Purview sensitivity labels | Verify | E5 includes Purview — confirm labels are applied to Finance libraries |
| Copilot interaction logging | Enabled by default | Confirm audit log retention period meets Finance compliance requirements |
| DLP policies covering financial data | Verify | Ensure existing DLP policies extend to Copilot prompt and response context |
| Conditional Access — Copilot app | Review | Confirm Finance users are covered by existing CA policies; no exclusions |
| Guest/external user access | Review | Ensure no external users have access to Finance SharePoint sites that Copilot could traverse |

---

## 6. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Copilot surfaces restricted financial content to users who have legacy inherited access | High (given unaudited permissions) | High | Block licence assignment until permission audit is complete |
| Users prompt Copilot with client financial data in Teams chat or email | Medium | High | Finance-specific acceptable use guidance; DLP policy coverage for Copilot |
| Board pack content summarised and distributed beyond intended audience | Medium | Very High | Sensitivity label enforcement; restrict Copilot licence for board pack custodians until label coverage is confirmed |
| Low user adoption due to lack of trust in AI outputs | Medium | Low | Structured prompt guidance session; clear escalation path for incorrect outputs |
| M&A document exposure via Copilot response | Low (if audit complete) | Very High | Quarantine M&A libraries with restricted permissions and label enforcement before any licence is live |

---

## 7. Stakeholders and Sign-off

| Role | Name / Team | Sign-off required for |
|---|---|---|
| Finance leadership | Finance Director / CFO office | Phase 0 permission audit scope; Phase 1 go/no-go |
| IT Security | Security team | Permission audit completion; DLP and label coverage |
| Data Governance | Governance / Legal | AI usage charter coverage; compliance controls |
| SharePoint admin | IT / Microsoft 365 team | Permission remediation; label application |
| Change & Release | IT | Phase 1 and Phase 2 change window approval |

---

## 8. Next Actions

1. **Immediate:** Initiate SharePoint permission inheritance report for all Finance sites and libraries.
2. **This week:** Confirm with Legal/Policy whether the DWP Personal AI Usage Charter requires a Finance-specific addendum.
3. **This week:** Identify pilot cohort (10–15 users) and confirm with Finance leadership.
4. **Before Phase 1:** Complete permission remediation and obtain sign-off from IT Security and Finance leadership.
5. **Before Phase 1:** Assign Copilot licences only to pilot group via Entra group-based licensing.
