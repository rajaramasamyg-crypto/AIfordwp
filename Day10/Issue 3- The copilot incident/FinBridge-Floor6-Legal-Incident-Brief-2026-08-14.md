# FinBridge Floor 6 Legal Incident Brief (Partner-Ready)

**Date:** 2026-08-14  
**Department:** Floor 6 Legal (45 users, recently migrated to Windows 11 and Intune)  
**Audience:** Legal partners and non-technical leadership

## What is actually going on

Two different problems appeared at the same time:

1. **Potential confidentiality incident (critical):** A paralegal reported Copilot showed a client matter she says she has never had access to.
2. **Desktop shortcuts missing (high, operational):** Users report vanished desktop shortcuts after Friday's document management app rollout.

These are related in timing, but not yet proven to be the same root cause.

## What the "pulled up a matter she never had access to" line actually is

That statement is **not** a normal support ticket. It is a **potential unauthorized information disclosure event** and must be handled as a security/compliance incident until evidence proves otherwise.

### What we would NOT do

- Do not close it as "AI weirdness."
- Do not treat it as user confusion without validating effective permissions and audit evidence.
- Do not continue broad Copilot expansion in Legal until initial containment checks complete.

### Two-sentence escalation (required)

Escalation: Potential confidentiality incident in Floor 6 Legal: a paralegal reports Copilot surfaced a client matter she states she was never authorized to access, indicating possible unauthorized disclosure via AI retrieval. Please open a Sev-2 security incident now, preserve Copilot/M365 audit evidence, and engage Security Operations, M365/Intune engineering, and Legal/Compliance to validate effective permissions, contain exposure, and complete breach assessment.

## What we check first (evidence we must collect)

### A. Copilot confidentiality event (first 30-60 minutes)

- Reporter identity, exact timestamp, exact Copilot prompt, and screenshot of response.
- Matter details: client/matter ID, document name, storage location (SharePoint/Teams/OneDrive/shared drive).
- User's **effective access** at incident time:
  - Entra group membership
  - SharePoint/Teams permissions
  - Shared mailbox or channel membership
- M365 Unified Audit / Copilot interaction logs for the timestamp window.
- Purview alerts, DLP events, and sensitivity label state for the referenced content.

Decision point:
- If user had technical read access: this is most likely an over-permission/configuration issue.
- If user did not have access: treat as confirmed unauthorized disclosure path and escalate containment immediately.

### B. Missing desktop shortcuts (first 30-90 minutes)

- Impact scope: single user vs multiple users vs all 45.
- Whether `.lnk` files are truly deleted or only hidden/unrendered.
- Correlation with app rollout timing and version.
- Installer and Intune deployment logs (including any profile cleanup actions).
- OneDrive Desktop sync status and profile health on affected devices.

Decision point:
- If shortcuts are hidden: restore visibility quickly.
- If deleted and widespread: pause further rollout and remediate before additional deployment.

## What we do right now

1. Open and classify the Copilot item as a security incident (Sev-2).
2. Preserve evidence immediately (audit logs, user statement, screenshot, timestamps).
3. Run effective-permission validation on the reported matter.
4. Put a temporary change freeze on additional Legal Copilot scope changes until first findings return.
5. Start a rapid impact survey for shortcut loss across all Floor 6 users.
6. Restore shortcuts for impacted users now (manual/scripted), while root cause analysis continues.
7. Pause further document app rollout only if multi-user shortcut deletion is confirmed.

## Likely root cause (current confidence, pending evidence)

- **Most likely for Copilot issue:** Legacy or inherited over-permissions in M365 content stores surfaced by Copilot retrieval logic, not "Copilot inventing access."  
  Rationale: prior deployment context already flagged permission inheritance and high sensitivity risk.
- **Most likely for shortcut issue:** Installer/profile cleanup side effect or policy/sync interaction during app deployment.

## What we tell partners by lunch (non-technical script)

"We are handling two separate issues. One is a potential confidentiality event involving Copilot, and we are treating it as a formal security incident until we confirm exact access rights and audit evidence."

"The second issue is missing desktop shortcuts after Friday's app rollout; we are restoring user productivity immediately and will confirm by lunch whether this is isolated or rollout-wide, with a fixed remediation plan and owner."

## By-lunch deliverables we commit to

- Confirmed incident classification and scope statement for the Copilot event.
- Initial findings: whether the user had effective technical access at time of query.
- Containment status and next security milestones (same day).
- Shortcut impact count and restoration progress.
- Go/no-go recommendation on continuing the document app rollout.

## What success looks like by end of day

- Copilot event either downgraded with evidence or escalated with full incident controls active.
- Any over-permission paths identified and remediation owners assigned.
- Shortcuts restored for affected users and recurrence control agreed with app owner/vendor.
- Single communication thread maintained for Legal leadership with clear timestamps and accountable owners.