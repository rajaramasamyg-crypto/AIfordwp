# Incident Triage — Unauthorized Data Exposure via Copilot (Floor 6, Legal)
**Date:** 2026-08-14  
**Prepared by:** DWP Service Desk / Security Triage  
**Status:** ESCALATE IMMEDIATELY  
**Severity:** CRITICAL / DATA SECURITY INCIDENT

---

## What This Actually Is

This is **NOT** a Copilot software defect or "AI weirdness." This is a **data security incident** combined with a **permissions control failure**.

### The Real Problem
Copilot can only surface content to which the signed-in user already has read access. If the paralegal received a confidential client settlement document through Copilot, her account account already possesses underlying SharePoint/drive read permissions to that document. 

**This means:**
- Her user account is a member of a security group (or has inherited permissions) that grants access to restricted content
- She was likely never *assigned* to the matter in the project management system, but has *technical read access* anyway
- This access likely came from the 2019 SharePoint migration's unaudited permission inheritance state (confirmed in pre-deployment audit as a blocker)
- Copilot simply made the problem *visible* by surfacing it in a response

---

## What NOT To Do

❌ **Do NOT close this as "Copilot returned incorrect results"**  
❌ **Do NOT treat this as a Copilot support ticket requiring a feature toggle**  
❌ **Do NOT dismiss it as isolated user error**  
❌ **Do NOT wait for a standard IT Service Desk ticket workflow**  
❌ **Do NOT assume it's a one-off occurrence**  

This is a **control failure** — if one user has unintended access, others likely do too.

---

## Why This Matters

Floor 6 is **Legal**, working with confidential client matter documents. The implications:

| Risk Domain | Impact |
|---|---|
| **Regulatory** | GDPR breach (unauthorized personal data access); FCA compliance violation; contractual breach with clients |
| **Legal** | Attorney-client privilege violation; discovery exposure if litigation occurs |
| **Compliance** | Control failure in access governance; potential data protection audit finding |
| **Board/Reputation** | Material control weakness; potential disclosure obligation if data exposure affected personal/sensitive client data |

---

## Two-Sentence Escalation

**"A paralegal on Floor 6 (Legal) received a confidential client settlement document via Copilot from a matter she was never assigned to, indicating a permissions misconfiguration—likely unaudited inheritance from the 2019 SharePoint migration. This requires immediate investigation by Security/Compliance and a full audit of Finance-Legal SharePoint access controls before any further Copilot rollout."**

---

## Immediate Triage Actions

### Step 1: Confirm Direct Access (5 min)
Ask the paralegal: "Without using Copilot, can you navigate to this file in SharePoint and open it directly?"
- **If YES** → Permissions misconfiguration confirmed. Go to Step 2.
- **If NO** → Escalate to Security + Copilot product engineering (potential data indexing issue).

### Step 2: Permission Audit (Parallel, urgent)
Security team must run immediately:
1. Identify all security groups with read access to the file/folder containing the settlement matter
2. Confirm paralegal's group membership chain
3. Check if access is inherited, direct, or delegated
4. Cross-reference with project assignment system to identify the gap

### Step 3: Blast Radius Assessment (Parallel)
- Audit Floor 6 and Finance team members for similar over-permissive access patterns
- Scan for any other Copilot-surfaced content complaints in recent weeks (may be unreported)
- Check access logs to see if the paralegal accessed similar restricted content in the past

---

## Escalation Routing

- **Primary:** Security Operations Center (SOC) + Data Governance  
- **Secondary:** Legal/Compliance + Finance leadership  
- **Copy:** IT Service Delivery Lead + Copilot Deployment Owner  
- **Decision Required:** Pause any further Copilot rollout to legal/finance departments until permission audit is complete and control remediation is verified
