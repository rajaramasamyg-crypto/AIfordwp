# Triage Summary — Legal Team Lost Copilot Access This Morning

**Logged:** 2026-08-12  
**Analyst:** DWP Service Desk

---

## Summary
All 40 people on the Legal team report that Copilot access disappeared this morning after working normally last week. This looks like a team-wide change rather than an individual device issue.

## Impact
- **Who:** Legal team members
- **How many affected:** Approximately 40 users reported; confirm exact count
- **Business urgency:** HIGH — a whole team losing Copilot access is a service-impacting issue and likely tied to licensing, policy, or tenant health

## Known Facts
- Access worked last week
- Access is now missing for the full Legal team this morning
- The issue appears to affect many users at once
- The failure is likely not specific to a single device or mailbox

## Missing Information to Gather
1. Exact number of affected users and whether any users are unaffected
2. Whether the users lose Copilot in all apps or only one app (for example, Word, Outlook, or SharePoint)
3. Whether the Copilot icon, chat, or entry point is missing entirely or returns an error
4. Whether any other Microsoft 365 services are also affected
5. Whether the Legal team uses a dedicated security group for licensing
6. Whether any recent licence assignment, group membership, or policy changes were made overnight
7. Whether Microsoft 365 service health shows an active incident or advisory
8. Whether conditional access, compliance, or tenant restrictions changed this morning
9. Whether the affected accounts are all in the same region or tenant segment
10. Whether the issue started at the same time for everyone or rolled out gradually

## Likely Category
**Microsoft 365 / Copilot Service or Licensing Issue — Team-wide loss of access**  
Sub-category: Licence removal, policy change, or service health incident affecting a shared user group

## Suggested First Diagnostic Step
Check Microsoft 365 service health and compare Copilot licence assignment for several affected Legal users against a known-good account. If licences are still present, review recent group membership and policy changes for the Legal team, then confirm whether the problem is tenant-wide or limited to a specific app. A sudden, same-day loss across 40 users strongly suggests an admin-side change or service incident rather than a local user problem.