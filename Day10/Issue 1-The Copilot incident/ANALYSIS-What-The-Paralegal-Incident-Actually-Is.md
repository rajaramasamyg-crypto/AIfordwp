# Analysis: "Pulled Up A Matter She's Never Had Access To"
**Date:** 2026-08-14  
**Context:** FinBridge Floor 6 (Legal, 45 people, Win11 + Intune enrolled)  
**Classification:** SECURITY INCIDENT — Not a support ticket, not "AI weirdness"

---

## What This Actually Is

The paralegal's experience is **NOT a Copilot malfunction or defect.**

It is a **PERMISSIONS MISCONFIGURATION masquerading as a Copilot problem.**

### The Reality
- **Copilot functioned correctly:** It respected the signed-in user's underlying SharePoint read permissions and returned content accessible to her account.
- **The root cause is elsewhere:** The paralegal's user account has inherited read access to a confidential client matter through over-permissive security group nesting or unaudited permission inheritance from the 2019 SharePoint migration.
- **Copilot exposed the misconfiguration:** By surfacing content the user technically has access to, Copilot revealed a hidden permissions defect that would have gone unnoticed with traditional access patterns.
- **This is a regulatory risk:** If the client matter contains confidential settlement drafts, financial data, or protected information, the unauthorized exposure may trigger GDPR, FCA, or contractual breach obligations.

### Why This Matters
Misclassifying this as "AI weirdness" would:
1. **Delay critical remediation** of the underlying permissions problem
2. **Miss the broader exposure risk** — the paralegal is unlikely to be the only user with unintended access
3. **Create compliance and audit liability** — if the client discovers this exposure via a security audit or breach notification, IT will need to report that it was identified and handled as a security incident, not dismissed as a technical glitch
4. **Waste security investigation time** debugging Copilot when the issue is in SharePoint permissions

---

## What You Would NOT Do

❌ **DO NOT close this as "AI weirdness" or a Copilot bug**

This dismissal would:
- Treat a **regulatory incident** as a **technical support ticket**
- Fail to escalate to Legal/Compliance leadership
- Leave over-permissive permissions in place, allowing the exposure to continue
- Create a documentation trail showing IT did not treat this as a security incident
- Violate incident management standards for data protection breaches

**Correct action:** Escalate immediately as a **SECURITY INCIDENT** to IT Security + Legal/Compliance, NOT to Copilot product support.

---

## Two-Sentence Escalation

**"A paralegal accessing Copilot received a confidential client settlement matter in the response; investigation confirms she has underlying SharePoint read access via inherited permissions from the 2019 migration. This indicates the pre-deployment sharepoint permissions audit was not completed before Copilot licence assignment, creating regulatory exposure (GDPR/FCA) for unauthorized confidential data access; IT Security + Legal/Compliance must immediately audit all Floor 6 Legal users' permissions to a sensitive matter folder and determine if removal or remediation is required."**

---

## Classification Summary

| Attribute | Value |
|---|---|
| **Incident Type** | Security Incident — Unauthorized Data Access |
| **Severity** | CRITICAL |
| **Root Cause Domain** | Permissions / Data Governance (SharePoint), NOT Copilot |
| **Regulatory Impact** | GDPR / FCA / Client Contract Breach Potential |
| **Escalation Required?** | YES — Immediate (IT Security + Legal/Compliance) |
| **Copilot License Rollback?** | Conditional on audit completion |
| **Correct Team** | IT Security / SharePoint Admin / Legal / Compliance, NOT Copilot Product Support |

