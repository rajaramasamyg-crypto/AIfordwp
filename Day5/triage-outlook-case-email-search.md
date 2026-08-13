# Triage Summary — Copilot in Outlook Cannot Find Case Emails

**Logged:** 2026-08-12  
**Analyst:** DWP Service Desk

---

## Summary
A new associate reports that Copilot in Outlook cannot find any of the case emails needed for context. The user started this week, so the mailbox and search index may still be settling.

## Impact
- **Who:** Single user (new associate; identity to confirm)
- **How many affected:** 1 reported; whether other new joiners have the same issue — to confirm
- **Business urgency:** MEDIUM-HIGH — the user may be blocked from finding case history, especially if they are onboarding to active matters

## Known Facts
- User started this week
- Copilot in Outlook cannot find the case emails the user expects
- The issue may involve mailbox indexing, sync delay, the wrong mailbox/profile, or limited access to the relevant mailboxes
- The user needs case context from email history

## Missing Information to Gather
1. User name, staff ID, and primary email address
2. Whether the emails are in the user's own mailbox or a shared mailbox
3. Exact search terms or prompt used in Outlook Copilot
4. Whether the emails can be found by normal Outlook search
5. Whether Outlook shows the mailbox as fully synced and up to date
6. Whether the user is using the correct Outlook profile and account
7. Whether the case emails are in Inbox, Archive, a shared mailbox, or another folder
8. Whether the mailbox was recently provisioned or migrated
9. Whether other apps such as Teams or SharePoint can see the same case context
10. Whether the user has the required permissions to the shared mailbox or matter mailbox

## Likely Category
**Outlook / Search and Indexing — New mailbox or shared mailbox not yet fully indexed, or permissions not yet in place**  
Sub-category: Copilot cannot retrieve content that Outlook search has not indexed or that the user cannot access

## Suggested First Diagnostic Step
Confirm whether the case emails can be found by normal Outlook search before testing Copilot again. If Outlook search also fails, leave Outlook open and connected so indexing can complete, then verify mailbox sync status and the exact folder location of the messages. If the messages live in a shared mailbox, confirm the user has Full Access and that the mailbox has been added correctly to their profile. If normal search works but Copilot still misses the emails, check whether the mailbox index needs more time to update or whether the prompt needs a more specific folder or sender reference.