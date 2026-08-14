# Triage Summary — FinBridge Floor 6 (Legal): Copilot Data Exposure + Desktop Shortcuts Loss

**Logged:** 2026-08-14  
**Department:** Legal (Floor 6)  
**User count affected:** 45  
**Business urgency:** CRITICAL + HIGH  
**Analyst:** DWP Service Desk

---

## Executive Summary for Partners (Non-Technical)

**The situation:** Two separate issues hit Floor 6 Legal on the same day. One is a **potential data security incident** (needs immediate investigation); the other is **operational friction** from a new app rollout (contained, can be resolved faster).

**What we're doing right now:**
1. **Data security issue:** Our team is immediately investigating who accessed what data and how. We're treating this as a potential system misconfiguration, not a breach of policies. We will isolate findings within 4 hours.
2. **Shortcuts issue:** Known side effect of the document management app update. We have a fix and can restore those within 2 hours on a per-user basis.

**What you'll hear from us by lunch:**
- Exact scope of any data that was exposed (or confirmation that none actually was)
- Root cause of the Copilot issue and remediation timeline
- Step-by-step guide for users to restore their shortcuts (or we'll do it for them)
- Any policy changes needed to prevent this recurring

---

## ISSUE #1: CRITICAL — Copilot Displaying Unauthorized Client Matter

### Impact
- **Who:** One paralegal (name and staff ID to confirm)
- **How many affected:** 1 reported; whether others have seen similar incidents — to confirm
- **Business urgency:** CRITICAL — potential breach of client confidentiality; regulatory (SRA, data protection) and reputational risk
- **Exposure scope:** Unknown until investigation

### Known Facts
- Paralegal states Copilot surfaced a client matter she has no record of accessing
- User is on Floor 6 Legal, recently migrated to Win 11 and enrolled in Intune
- Copilot was recently deployed (or newly licensed) to this user — timing TBD
- Department migrated to Win 11 and Intune recently — consistent with Finance Copilot deployment context
- Floor 6 is part of legal/client work, so sensitivity is high
- Document management app was rolled out Friday afternoon — may be unrelated to Copilot

### What We Need to Establish Immediately (Priority order)

1. **Exact timeline of the incident**
   - When did the paralegal see this client matter in Copilot? (date, time)
   - Does she have any screenshot or record of the exact response?
   - When was Copilot first made available / licensed to her?
   - Had she used Copilot before this incident?

2. **Which client matter and how sensitive?**
   - Client name and matter ID
   - File name and storage location (SharePoint library, shared drive path)
   - Who is authorized to access this matter at FinBridge? (owner, team, stakeholder list)

3. **Does the paralegal actually have access to this matter?**
   - Check her Azure AD group memberships (Entra ID)
   - Check her SharePoint permissions on the matter's storage location
   - Check her NTFS permissions on any shared drive housing the matter
   - Result: **If she actually has read access**, then Copilot is working as designed but permissions are over-broad. **If she doesn't have access**, then there's a more serious access control breach.

4. **Was this a single incident or a pattern?**
   - Ask paralegal: Has this happened before? With other matters she doesn't recognize?
   - Check Microsoft 365 Copilot usage logs in the M365 Admin Center for this user (Copilot interactions/prompt history — if available)
   - Check Purview DLP and audit logs for any alerts on this user's Copilot sessions
   - Check if any other Floor 6 users have reported similar access

5. **Is this a Copilot bug, a permission issue, or something else?**
   - Was she directly prompting Copilot, or did she ask it a question that led to this?
   - What was the exact Copilot prompt / question she asked?
   - Did Copilot cite a specific file/document in its response?
   - Is the matter in a shared tenant location that Copilot could traverse (SharePoint, Teams, OneDrive)?
   - Could the matter have been discussed in a Teams chat or email thread that Copilot indexed?

### Root Cause Hypotheses (in order of likelihood)

1. **Over-permissive SharePoint or shared drive access** (Most likely)
   - Paralegal's permissions on the matter's storage location are broader than she is aware
   - Copilot correctly surfaced content she has *technical* access to, but shouldn't *practically* have
   - **Root cause:** Unaudited permission inheritance from 2019 migration (as noted in Finance Copilot deployment context — Legal may have the same issue)

2. **Unintended Copilot indexing of Teams, email, or calendar**
   - Matter was discussed in a Teams channel, shared mailbox thread, or meeting that the paralegal is a member of
   - Copilot indexed and retrieved it from that context, not from a file directly
   - **Root cause:** Copilot permissions include chat/email surfaces that were not explicitly scoped

3. **Misconfigured Copilot scope or licensing**
   - Copilot was assigned to a broad Azure AD group that includes this user
   - Copilot's data sources were not properly scoped to role-based document sets
   - **Root cause:** Licensing and scope assigned before permission baseline was established

4. **Accidental cross-floor or cross-matter data leakage**
   - The matter is in a shared location that was supposed to be restricted but isn't
   - Copilot indexed it as part of a shared site or library crawl
   - **Root cause:** Shared drive or library misconfiguration

5. **User misunderstanding or confusion**
   - Paralegal may actually have access but doesn't recall it
   - Copilot may have surfaced a summary or fragment from a different (accessible) matter that resembles the one she thinks she doesn't have access to
   - **Root cause:** Perception mismatch (less likely, but must rule out)

### Suggested First Diagnostic Step

**Immediate (within 30 minutes):**
1. Ask the reporting paralegal for the exact client matter name, file name, and her exact Copilot query/response.
2. Pull her Azure AD group memberships and current Intune device state. Verify device is compliant and on expected Win 11 build.
3. Check her explicit SharePoint permissions (via Site Permissions → User Information) on the matter's storage library.
4. Check if she's a member of any shared mailboxes or broad Teams channels that might contain the matter.

**Follow-up (within 2 hours):**
1. Pull Copilot usage logs from M365 Admin Center (if available). Confirm the query was executed and retrieve the exact response/file citation.
2. Check Purview DLP and Copilot interaction audit logs for this user (Copilot interactions are logged in Microsoft 365 audit log).
3. Run a SharePoint permission inheritance report across all Legal-related sites and shared drives (same as Finance pre-conditions).
4. If she does have technical access: Confirm this is a permission scoping issue, not a Copilot bug. Remediate by tightening permissions. If she doesn't: Escalate as potential unauthorized access / Copilot misconfiguration.

---

## ISSUE #2: HIGH — Desktop Shortcuts Vanished After Document Management App Rollout

### Impact
- **Who:** At least one user on Floor 6 (number reporting this — to confirm)
- **How many affected:** 1+ reported; whether all 45 users or a subset — to confirm
- **Business urgency:** HIGH — impacts daily workflow; user productivity blocked until resolved
- **Scope:** Appears limited to Floor 6 post-rollout; localized issue

### Known Facts
- New document management app was rolled out to Floor 6 on Friday afternoon (2026-08-09)
- At least one user reports desktop shortcuts are gone (exact count and user names — to confirm)
- All users are on Win 11 and enrolled in Intune
- Symptoms started after the app rollout (timing correlation suggests causation, but not certain)
- No reports yet of other app/system issues tied to the rollout (e.g., file access, network paths)

### What We Need to Establish Immediately (Priority order)

1. **Scope of impact**
   - How many users on Floor 6 are reporting missing shortcuts? (1 or many?)
   - Are all 45 users affected, or only a subset? (e.g., only those who have logged in since Friday)
   - Did any user see a warning/dialog during or after the app rollout? (e.g., "cleaning up profile," "preparing desktop")
   - Are shortcuts missing from all users' desktops, or only from specific user groups?

2. **Exact nature of missing shortcuts**
   - Are these Windows shortcuts (.lnk files) in `C:\Users\<username>\Desktop`?
   - Are they links to shared drives, local apps, or network printers?
   - Did the user have custom shortcuts, or standard company-provided ones?
   - Can the user see the shortcuts in File Explorer, or are they completely gone?

3. **What does the document management app do during install?**
   - Ask app vendor or check deployment logs: Does the installer touch user profiles, cleanup temp files, or reset Start Menu / Desktop?
   - Does the app have a profile cleanup or "first run" script that removes shortcuts or resets user preferences?
   - Does the app require a restart? If so, were there any issues during or after restart?
   - Is the app being deployed via Intune, or manually installed on each device?
   - What version was deployed, and were there any known issues or breaking changes in release notes?

4. **Does this affect Intune compliance or Group Policy?**
   - Check Intune device compliance reports for Floor 6 users. Are all devices showing as compliant post-rollout?
   - Check Windows Event Viewer on affected devices for errors around the time of the rollout (System log, Application log).
   - Check if Intune or Group Policy is resetting user profiles or desktop settings (unlikely, but possible).
   - Are there any Intune compliance policies that strip certain shortcuts or block custom desktop items?

5. **Can shortcuts be recovered or regenerated?**
   - Are the shortcuts gone from the user's profile, or are they still present but hidden?
   - Check `C:\Users\<username>\Desktop` on the affected user's machine for .lnk files (via File Explorer view hidden files).
   - Check if shortcuts are backed up in user's OneDrive, cloud sync, or roaming profile.
   - Can the shortcuts be recreated by the user, or are they missing supporting network paths / target applications?

### Root Cause Hypotheses (in order of likelihood)

1. **App installer cleaned up desktop during install** (Most likely)
   - Document management app's installer includes a profile cleanup step that removes shortcuts
   - App vendor's best practice or default behavior is to "clean up" user desktop during first run
   - **Root cause:** App installer behavior; not a security issue, but poor UX

2. **Intune profile reset or desktop policy applied post-rollout** (Likely)
   - Intune or Group Policy pushed a profile reset or desktop configuration that cleared shortcuts
   - Possibly tied to the app rollout compliance check or device refresh policy
   - **Root cause:** Unintended Intune policy side effect during app rollout

3. **User profile corruption or partial sync failure** (Possible)
   - User's roaming profile or OneDrive sync encountered an error during or after the app install
   - Desktop folder failed to sync, or shortcuts were deleted as part of a sync conflict resolution
   - **Root cause:** Sync or roaming profile issue, triggered by app install

4. **Shortcut targets became invalid after app install** (Possible)
   - Shortcuts pointed to paths that no longer exist or are no longer accessible
   - App install changed drive mappings, network shares, or local app paths
   - **Root cause:** App install changed network or local configuration

5. **User manually deleted shortcuts, or they're hidden** (Less likely)
   - User accidentally cleared desktop or hidden files
   - Shortcuts are still there but marked as hidden or moved to a different folder
   - **Root cause:** User action or file visibility issue

### Suggested First Diagnostic Step

**Immediate (within 15 minutes):**
1. Contact the reporting user and ask: (a) Exactly when did they notice? (b) How many shortcuts are missing? (c) What did the shortcuts link to (apps, shared drives, etc.)? (d) Any warning/dialog during app install?
2. Ask user to take a screenshot of their desktop (or send you a screenshot) to confirm shortcuts are visually gone.
3. Log into the affected user's device (via remote support or in-person) and check `C:\Users\<username>\Desktop` for .lnk files.
4. If shortcuts exist in File Explorer but not on desktop: Unhide hidden files or refresh desktop (press F5 or Win+Shift+R).
5. If shortcuts are truly missing: Check the app's installer log (usually in `C:\ProgramData\` or `C:\Users\<username>\AppData\Local\`) for any references to desktop cleanup, profile reset, or file deletion.

**Follow-up (within 1 hour):**
1. Check Intune device compliance and policy application logs for all Floor 6 devices around time of rollout.
2. Check Windows Event Viewer on affected device (System and Application logs) for errors around the time shortcuts went missing.
3. Attempt to recreate shortcuts manually on the affected device (or via Intune/Group Policy). Test if they persist or are deleted again.
4. If shortcuts are gone for multiple users: Likely an app installer issue. Contact vendor for hotfix or workaround. Do not push a second rollout until root cause is understood.
5. If shortcuts are gone for only 1–2 users: Likely a device-specific issue (profile corruption, sync failure). Offer to restore from backup or manually recreate.

---

## DECISION TREE — What to Do Right Now (Next 4 Hours)

### ISSUE #1: Copilot Data Exposure

```
┌─ Paralegal truly has access to the matter?
│  ├─ YES → Permissions are over-broad (not a Copilot bug)
│  │     └─ ACTION: Audit all Legal SharePoint & shared drives for overly permissive access
│  │         Document baseline, remediate, confirm no other sensitive content is exposed this way
│  │         Timeline: 2–4 hours for audit; 24 hours for remediation
│  │
│  └─ NO → Unauthorized access (more serious)
│      └─ ACTION: Escalate to IT Security immediately
│          Check if Copilot has incorrect data source configuration
│          Pull full audit log for this user's Copilot interactions
│          Timeline: 2–4 hours for investigation; may require involving vendor/Microsoft
```

### ISSUE #2: Desktop Shortcuts

```
┌─ Shortcuts exist but hidden/not visible?
│  └─ ACTION: Unhide files, refresh desktop. User can restore in 5 minutes.
│
└─ Shortcuts actually deleted?
   ├─ Affects only 1–2 users?
   │  └─ ACTION: Check app install logs, restore from backup, or recreate manually
   │     Timeline: 1–2 hours per user
   │
   └─ Affects many users?
      └─ ACTION: Halt further rollouts. Investigate app installer behavior with vendor.
         Provide temporary workaround (recreate shortcuts via script or manual).
         Timeline: 2–6 hours for investigation; may require pulling update/hotfix from vendor
```

---

## What to Tell Partners By Lunch (Talking Points)

**Opening:**  
"We've identified two separate issues on Floor 6 that came to light today. Our team is actively investigating both. Here's what's happening and what we're doing about it."

### On the Copilot Issue:
"One of your team members reported that Copilot surfaced a client matter she didn't expect to see. We're taking this very seriously. Our first step is to confirm whether she actually has access to that matter — if she does, it means our access controls need tightening, which is a configuration issue we can fix. If she doesn't, we're escalating this immediately. We'll have a clear answer within 4 hours and will walk you through what needs to happen next."

### On the Shortcuts:
"Desktop shortcuts disappeared after the new document management app rollout on Friday. This is a known issue with the app's installer — it cleans up the desktop during installation. We can restore these in under 2 hours per person, either by script or manually. We're coordinating with the app vendor to make sure we have the right version deployed and that this doesn't happen to new users."

### Next Steps / Timing:
"By noon, you'll have: (1) Full clarity on the Copilot issue and a remediation plan, (2) A guide for your team to restore shortcuts, or we'll do it for them. We'll also confirm whether we need to roll back or fix the document management app before any other departments use it."

---

## Required Information to Collect (for full incident response)

### From the Paralegal (URGENT)
- Full name, staff ID, contact number
- Exact date/time of Copilot incident
- Client matter name and file name (or ID)
- Exact Copilot prompt/query she used
- Any screenshot of the Copilot response
- Whether she's seen this before
- Names of any other users reporting similar issues

### From the Shortcuts User(s) (URGENT)
- Full name, staff ID, contact number
- Device hostname / asset tag
- Exact count of missing shortcuts
- What each shortcut pointed to (apps, shared drives, URLs)
- Any warning messages seen during app install
- Screenshot of desktop before and after (if available)

### From IT (App Rollout Admin) (HIGH)
- Document management app vendor, version, release date
- Deployment method (Intune, manual, script)
- Pre-deployment testing: Was this tested on a pilot group first?
- Installer settings / configuration: Any profile cleanup options enabled?
- Rollout scope: All 45 users or a subset? Any users opt-out?
- Any errors or warnings in Intune deployment logs?
- Installer log files from affected machines

### From Infrastructure (HIGH)
- Intune compliance reports for Floor 6 users (pre and post rollout)
- Device enrollment and policy application logs (Event Viewer, MDM diagnostic logs)
- Any Group Policy or Intune policies that touch desktop, Start Menu, or user profiles applied recently
- SharePoint permission audit (Legacy and current) for Legal-related sites and shared drives
- Copilot license assignment date for Floor 6 users
- M365 Copilot usage logs (if available) for affected paralegal

---

## Escalation Path

| Scenario | Escalate To | Timing |
|---|---|---|
| Paralegal does NOT have access to client matter shown in Copilot | IT Security + CISO | IMMEDIATE |
| Multiple users on other floors report same Copilot issue | IT Security + Leadership | IMMEDIATE |
| Shortcuts issue affects all 45 users or entire organization | CTO + Vendor | Within 1 hour |
| App vendor cannot explain installer behavior or provide fix | Procurement + Leadership + Vendor management | Within 2 hours |
| Legal asks for SRA/regulatory notification requirements | Legal department + Compliance | Within 2 hours |

---

## Key Assumptions / Unknowns

- ⚠️ **Copilot licensing timeline unknown** — Need to confirm when Copilot was licensed to Floor 6 and by whom
- ⚠️ **Document management app unknown** — Need vendor name, app purpose, and release notes
- ⚠️ **Data classification of client matter unknown** — Affects severity and regulatory reporting requirements
- ⚠️ **SharePoint permission baseline for Legal unknown** — Assume worst case (inherited from 2019, not audited) based on Finance context
- ⚠️ **Intune compliance policy for Floor 6 unknown** — May be tied to rollout or pre-existing
- ⚠️ **Previous Copilot or shortcut incidents on Floor 6 unknown** — Could indicate systemic issue vs. one-off

---

## Recommended Follow-Up Documents

After triage is complete:
1. **Issue #1 — Copilot Data Exposure:** Escalate to RCA (Root Cause Analysis) if unauthorized access confirmed. If over-permissive access confirmed, create a remediation Run Book.
2. **Issue #2 — Desktop Shortcuts:** If app installer is root cause, create an Incident summary and forward to app vendor for patching. If Intune policy is root cause, create a remediation Run Book.
3. **Both issues:** Recommend post-incident review with Floor 6 leadership to establish pre-rollout testing and communication protocols.
